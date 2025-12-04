uniform vec3 resolution;   
uniform float time;   
uniform vec3 camPos;   

// NOTE: modify these to control performance/quality tradeoff
#define MAX_STEPS 128 // max number of steps to take along ray
#define MAX_DIST 128. // max distance to travel along ray

#define HIT_DIST .01 // distance to consider as "hit" to surface
#define PUMPKIN_CENTER vec3(0,1,5)

#define SCALE_XZ 0.15 // how close terrain features are from each other
#define SCALE_Y 2. // how much the height of features can vary

#define MAX_OCTAVES 8 // how many layers, or times the generator is run

/*
 * Terrain Generation
 */

// Hash function to give a 'random' gradient vector based on coords
vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)),
             dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float perlin(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // Gradient vectors at corners
    vec2 g00 = hash(i + vec2(0.0, 0.0));
    vec2 g10 = hash(i + vec2(1.0, 0.0));
    vec2 g01 = hash(i + vec2(0.0, 1.0));
    vec2 g11 = hash(i + vec2(1.0, 1.0));

    // Distance vectors
    vec2 d00 = f - vec2(0.0, 0.0);
    vec2 d10 = f - vec2(1.0, 0.0);
    vec2 d01 = f - vec2(0.0, 1.0);
    vec2 d11 = f - vec2(1.0, 1.0);

    // Dot products
    float s00 = dot(g00, d00);
    float s10 = dot(g10, d10);
    float s01 = dot(g01, d01);
    float s11 = dot(g11, d11);

    // Fade curves (quintic)
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    // Bilinear interpolation
    float nx0 = mix(s00, s10, u.x);
    float nx1 = mix(s01, s11, u.x);
    return mix(nx0, nx1, u.y);
}

// Uses FBM to generate multi-octave noise
float perlinHeight(vec2 p)
{
    float h = 0.0;
    float amp = 1.0;
    float freq = 1.0;

    for (int i = 0; i < MAX_OCTAVES; i++) {
        h += amp * perlin(p * freq);
        amp *= 0.5;
        freq *= 1.7;
    }

    return h;
}

// SDF for generated heightmap-based terrain
vec2 Terrain(vec3 p)
{
    float height = perlinHeight(p.xz * SCALE_XZ) * SCALE_Y;

    float d = p.y - height;

    return vec2(d, 1.0);
}

/*
 * Helpers: rotate point p around axis by angle (in degrees).
 */

vec3 rotX(vec3 p, float angle) {
    float s = sin(radians(angle));
    float c = cos(radians(angle));
    return mat3(
        1, 0, 0,
        0, c, -s,
        0, s, c) * p; 
}

vec3 rotY(vec3 p, float angle) {
    float s = sin(radians(angle));
    float c = cos(radians(angle));
    return mat3(
        c, 0, s,
        0, 1, 0,
       -s, 0, c) * p; 
}

vec3 rotZ(vec3 p, float angle) {
    float s = sin(radians(angle));
    float c = cos(radians(angle));
    return mat3(
        c, -s, 0,
        s, c, 0.0,
        0, 0, 1) * p; 
}

/*
 * Helper: determines the material ID based on the closest distance.
 */
float getMaterial(vec2 d1, vec2 d2) {
    return (d1.x < d2.x) ? d1.y : d2.y;
}

/*
 * Hard union of two SDFs.
 */
float unionSDF( float d1, float d2 )
{
    return min(d1, d2);
}

/*
 * Hard difference of two SDFs.
 */
float subtractionSDF(float d1, float d2)
{   
    return max(-d1, d2);
}   

/*
 * Smooth union of two SDFs.
 * Resource: `https://iquilezles.org/articles/smin/`
 */
float smoothUnionSDF( float d1, float d2, float k )
{
    k *= 4.0;
    float h = max(k-abs(d1-d2), 0.0);
    return min(d1, d2) - h*h*0.25/k;
}

/*
 * Smooth difference of two SDFs.
 */
float smoothSubtractionSDF(float d1, float d2, float k)
{
    return -smoothUnionSDF(d1, -d2, k);
}

/*
 * Computes the signed distance function (SDF) of a plane.
 * https://iquilezles.org/articles/distfunctions/
 *
 * Parameters:
 *  - p: The point in 3D space to evaluate.
 *
 * Returns:
 *  - A vec2 containing:
 *    - Signed distance to the surface of the plane.
 *    - An identifier for material type.
 */
vec2 Plane(vec3 p)
{
    vec3 n = vec3(0, 1, 0); // Normal of the plane
    float h = 0.0; // Height offset
    return vec2(dot(p, n) + h, 1.0);
}

/*
 * Sphere SDF. https://iquilezles.org/articles/distfunctions/
 *
 * Parameters:
 *  - p: The point in 3D space to evaluate.
 *  - c: The center of the sphere.
 *  - r: The radius of the sphere.
 *
 * Returns:
 *  - A vec2 containing:
 *    - Signed distance to the surface of the sphere.
 *    - An identifier for material type.
 */
vec2 Sphere(vec3 p, vec3 c, float r)
{
    return vec2(length(p-c) - r, 2.0);
}

vec2 RibbedSphere(vec3 p, vec3 c, float r, float amp, float freq)
{
    vec3 q = p - c;

    float a = atan(q.z, q.x);

    float ribbedRadius = r + amp * sin(a * freq);

    float d = length(q) - ribbedRadius;

    return vec2(d, 2.0);
}

/*
 * Cylinder SDF. https://iquilezles.org/articles/distfunctions/
 *
 * Parameters:
 *  - p: The point in 3D space to evaluate.
 *  - c: The center of the cylinder.
 *  - r: The radius of the cylinder.
 *  - h: The height of the cylinder.
 *  - angle: Degree of rotation.
 *
 * Returns:
 *  - A vec2 containing:
 *    - Signed distance to the surface of the cylinder.
 *    - An identifier for material type.
 */
vec2 Cylinder(vec3 p, vec3 c, float r, float h, float angle)
{
    vec3 pt = p - c;

    pt = rotZ(pt, angle);

    vec2 d = abs(vec2(length(pt.xz), pt.y)) - vec2(r, h);
    float dist = min(max(d.x, d.y), 0.0) + length(max(d, 0.0));

    return vec2(dist, 3.0);
}

/*
 * Traingular Prism SDF. https://iquilezles.org/articles/distfunctions/
 *
 * Parameters:
 *  - p: The point in 3D space to evaluate.
 *  - c: The center of the prism.
 *  - dim: heigh and width of the prism (vec2).
 *  - angle: Degree of rotation.
 *
 * Returns:
 *  - A vec2 containing:
 *    - Signed distance to the surface of the prism.
 *    - An identifier for material type.
 */
vec2 TriPrism( vec3 p, vec3 c, vec2 dim, float angle )
{
    vec3 pt = p - c;

    pt = rotZ(pt, angle);

    vec3 q = vec3(abs(pt.x), pt.y, abs(pt.z));
    float d = max(q.z - dim.y, max(q.x * 0.866025 + q.y * 0.5, -q.y) - dim.x * 0.5);

    return vec2(d, 3.0);
}

/*
 * Rectangular Prism SDF. https://iquilezles.org/articles/distfunctions/
 *
 * Parameters:
 *  - p: The point in 3D space to evaluate.
 *  - c: The center of the rectangular prism.
 *  - dim: length, height, width of the rectangular prism (vec3).
 *
 * Returns:
 *  - A vec2 containing:
 *    - Signed distance to the surface of the rectangular prism.
 *    - An identifier for material type.
 */
vec2 RectPrism( vec3 p, vec3 c , vec3 dim )
{
    vec3 q = abs(p-c) - dim;
    return vec2(length(max(q,0.0)) + min(max(q.x, max(q.y, q.z)), 0.0), 3.0);
}

/*
 * Pumpkin SDF. Centered at PUMPKIN_CENTER.
 *
 * Parameters:
 *  - p: The point in 3D space to evaluate.
 *
 * Returns:
 *  - A vec2 containing:
 *    - Signed distance to the surface of the pumpkin.
 *    - An identifier for material type.
 */
vec2 Pumpkin(vec3 p, vec3 c, float r, vec3 rot) 
{
    float dist = MAX_DIST;
    float id = 0.0;

    vec3 q = p - c;
    q = rotX(q, rot.x);
    q = rotY(q, rot.y);
    q = rotZ(q, rot.z);

    float cavityR = r * 0.85;
    float stemH = r * 0.15;
    float eyeW = r * 0.25;
    float eyeH = r * 0.20;
    float noseW = r * 0.13;
    float noseH = r * 0.30;

    // Make the body
    vec2 body = RibbedSphere(q, vec3(0), r, 0.03, 12.0);
    dist = body.x;
    id = getMaterial(vec2(dist, id), body);

    // Make the cavity and hollow out pumpkin
    vec2 cavity = Sphere(q, vec3(0), cavityR);
    dist = subtractionSDF(cavity.x, dist);

    // Make the stem and union it to body
    vec3 stemOffset = vec3(0., r + stemH / 2., 0.);
    vec2 stem = Cylinder(q, stemOffset, r * .15, stemH, -5.);
    dist = smoothUnionSDF(dist, stem.x, 0.01);
    id = getMaterial(body, stem);

    // Make the eyes and carve them out
    vec3 eyeOffset1 = r * vec3(-0.35, 0.3, -0.87); // left eye
    vec3 eyeOffset2 = r * vec3(0.35, 0.3, -0.87);  // right eye
    vec2 eye1 = TriPrism(q, eyeOffset1, vec2(eyeW, eyeH), 0.);
    vec2 eye2 = TriPrism(q, eyeOffset2, vec2(eyeW, eyeH), 0.);
    dist = smoothSubtractionSDF(eye1.x, dist, 0.001);
    dist = smoothSubtractionSDF(eye2.x, dist, 0.001);

    // Make and carve out nose
    vec3 noseOffset = r * vec3(0., 0.0, -0.92); // centered between eyes, slightly in front
    vec2 noseDim = r * vec2(0.125, 0.2);         // width and height of triangular prism
    vec2 nose = TriPrism(q, noseOffset, noseDim, 0.0);
    dist = smoothSubtractionSDF(nose.x, dist, 0.001);

    // Mouth
    vec3 mouthOffset = r * vec3(0., -0.3, -0.9); // below center
    vec2 mouth = RectPrism(q, mouthOffset, r * vec3(0.3, 0.05, 0.2));
    vec3 fangOffset1 = r * vec3(0.3, -0.01, 0.);
    vec2 fang1 = TriPrism(q, mouthOffset + fangOffset1, r * vec2(.13, .2), 180.);
    vec3 fangOffset2 = r * vec3(-0.3, -0.01, 0.);
    vec2 fang2 = TriPrism(q, mouthOffset + fangOffset2, r * vec2(.13, .2), 180.);
    mouth.x = unionSDF(mouth.x, fang1.x);
    mouth.x = unionSDF(mouth.x, fang2.x);

    dist = smoothSubtractionSDF(mouth.x, dist, 0.01);

    return vec2(dist, id);
}

/*
 * Computes the signed distance to the closest surface in the scene.
 *
 * Parameters:
 *  - p: The point in 3D space to evaluate.
 *
 * Returns:
 *  - A vec2 containing:
 *    - Signed distance to the closest material.
 *    - An identifier for the closest material type.
 */
vec2 getSceneDist(vec3 p) {
    vec2 pumpkins = vec2(MAX_DIST, 0.);

    vec2 pumpkin0 = Pumpkin(p, PUMPKIN_CENTER - vec3(0., 0.5, 0.), 1.0, vec3(0., 0., -5.));
    pumpkins.x = unionSDF(pumpkins.x, pumpkin0.x);
    pumpkins.y = getMaterial(pumpkins, pumpkin0);

    vec2 pumpkin1 = Pumpkin(p, vec3(-2., 0.5, 4.), 0.8, vec3(0., -20., 20.));
    pumpkins.x = unionSDF(pumpkins.x, pumpkin1.x);
    pumpkins.y = getMaterial(pumpkins, pumpkin1);

    vec2 pumpkin2 = Pumpkin(p, vec3(1.5, -0.15, 3.5), 0.6, vec3(0., 30., -10.));
    pumpkins.x = unionSDF(pumpkins.x, pumpkin2.x);
    pumpkins.y = getMaterial(pumpkins, pumpkin2);

    vec2 terrain = Terrain(p);
    
    float dist = smoothUnionSDF(pumpkins.x, terrain.x, 0.01);
    float id = getMaterial(pumpkins, terrain);

    return vec2(dist, id);
}

/*
 * Performs ray marching to determine the closest surface intersection.
 *
 * Parameters:
 *  - ro: Ray origin.
 *  - rd: Ray direction.
 *
 * Returns:
 *  - A vec2 containing:
 *    - Distance to the closest surface intersection.
 *    - material ID of the closest intersected surface.
 */
vec2 rayMarch(vec3 ro, vec3 rd) {
	float d = 0.0;
	float id = 0.0;
    
    /*
     * TODO: Implement the ray marching loop for MAX_STEPS.
     *       At each step, use getSceneDist to get the nearest surface distance.
     *       Update the distance and material ID based on the closest surface.
     *       Break if the distance is less than HIT_DIST or the travelled distance is greater than MAX_DIST.
     *       Note, if MAX_DIST is reached, the material ID should be 0.0 (background color).
     */

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 ray_pos = ro + rd * d;
        vec2 sdf = getSceneDist(ray_pos);

        float min_dist = sdf.x;

        d += min_dist; 
        id = sdf.y;

        if (min_dist < HIT_DIST) {
            return vec2(d, id);
        }

        if (d > MAX_DIST) {
            return vec2(MAX_DIST, 0.0);
        }
    }

    return vec2(d, 0.0);
}

/* 
 * Helper: computes surface normal
 */
vec3 getNormal(vec3 p) {
	float d = getSceneDist(p).x;
    vec2 e = vec2(.01, 0);
    
    vec3 n = d - vec3(
        getSceneDist(p-e.xyy).x,
        getSceneDist(p-e.yxy).x,
        getSceneDist(p-e.yyx).x);
    
    return normalize(n);
}

/*
 * Helper: gets surface color.
 */
vec3 getColor(vec3 p, float id) 
{
    float sun_radius = 5.0;
    vec3 lightPos1 = vec3(
        sun_radius * cos(0.5 * time),
        2.0 + 3.0 * sin(0.5 * time), // oscillates between 2 and 5
        sun_radius * sin(0.5 * time)
    );

    //vec3 lightPos1 = vec3(3, 5, 2); // sunset
    vec3 lightPos2 = PUMPKIN_CENTER - vec3(0., 0.7, 0.); // position candle (centre of pumpkin)

    vec3 l1 = normalize(lightPos1 - p); 
    vec3 l2 = normalize(lightPos2 - p); 
    
    vec3 n = getNormal(p);
    
    // Diffuse terms
    float diffuse1 = clamp(dot(n, l1), 0.2, 1.0);
    float diffuse2 = clamp(dot(n, l2), 0.2, 1.0);

    // Perform shadow check using ray marching 
    { 
        // NOTE: Comment out to improve render performance
        float d1 = rayMarch(p + n * HIT_DIST * 2., l1).x;
        if (d1 < length(lightPos1 - p)) diffuse1 *= 0.1;

        float d2 = rayMarch(p + n * HIT_DIST * 2., l2).x;
        if (d2 < length(lightPos2 - p)) diffuse2 *= 0.1;
    }

    vec3 diffuseColor;

    switch (int(id)) {
        case 0: // background color 
            // should not get here
            break;
        case 1: // grass colour
            diffuseColor = vec3(111,193,45);
            break;
        case 2: // pumpkin body colour
            diffuseColor = vec3(255,103,0);
            break;
        case 3: // stalk colour
            diffuseColor = vec3(136,68,34);
            break;
        default: // background color 
            diffuseColor = vec3(255,147,0);
            break;
    }

    vec3 ambientColor = vec3(.9, .9, .9);
    float ambient = .1;
    
    vec3 lightColorSun = vec3(1.0, 0.55, 0.2);   // warm orange sunset
    vec3 lightColorCandle = vec3(1.0, 0.85, 0.6); // soft candlelight

    vec3 color = ambient * ambientColor
            + diffuse1 * lightColorSun * (diffuseColor / 255.0)
            + diffuse2 * lightColorCandle * (diffuseColor / 255.0);
    return color;
}

/*
 * Helper: camera matrix.
 */
mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main() {
    // Get the fragment coordinate in screen space
    vec2 fragCoord = gl_FragCoord.xy;
    
    // normalize to UV coordinates
    vec2 uv = (fragCoord - 0.5 * resolution.xy) / resolution.y;

    // NOTE: Look-at target (our pumpkin is centered here)
    vec3 ta = PUMPKIN_CENTER;

    // NOTE: Camera position (you may want to modify this for different views)
    // vec3 ro = vec3(0, 2, 0); // static
    vec3 ro = ta + vec3(5.0 * cos(0.2 * (camPos.x)), -0.5, 5.0 * sin(0.2 * camPos.x)); // orbit control
    // vec3 ro = ta + vec3(4.0 * cos(0.8 * time), 1.5, 4.0 * sin(0.8 * time)); // orbit time

    // Compute the camera's coordinate frame (view matrix)
    mat3 ca = setCamera(ro, ta, 0.0); 

    // Compute the ray direction for this pixel with respect ot camera frame
    vec3 rd = ca * normalize(vec3(uv.x, uv.y, 1));

    // Perform ray marching to find intersection distance and surface material ID
    vec2 dist = rayMarch(ro, rd); 
    float d = dist.x; 
    float id = dist.y; 

    // Surface intersection point
    vec3 p = ro + rd * d;

    // Compute surface color
    vec3 color;
    if (id == 0.0) {
        // Dynamic background from sun height
        float sunHeight = -5.0 * sin(time*0.5);

        float t = smoothstep(-0.5, 0.5, sunHeight / 10.0); // map sun height to [0,1]
        color = mix(vec3(238,64,21) / 255.0, vec3(0.0,0.0,0.0), t); // orange -> black
    } else {
        color = getColor(p, id);
    }

    // Apply gamma correction to adjust brightness (convert from linear to sRGB space)
    color = pow(color, vec3(0.4545)); 

    // Output the final color to the fragment shader
    gl_FragColor = vec4(color, 1.0); 
}