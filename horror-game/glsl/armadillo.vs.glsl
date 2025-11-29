// The uniform variable is set up in the javascript code and the same for all vertices
uniform vec3 orbPosition;
uniform float orbRadius;
uniform bool orbLightOn;

// This is a "varying" variable and interpolated between vertices and across fragments.
// The shared variable is initialized in the vertex shader and passed to the fragment shader.
out float intensity;
out vec3 aPos;

void main() {
    aPos = vec3(modelMatrix * vec4(position, 1.0)); // world space coordinates of vertex
    vec3 normalWorld = normalize(mat3(modelMatrix) * normal); // world-space normal

    vec3 lightDir = normalize(orbPosition - aPos);
    if (orbLightOn) {
        intensity = max(dot(normalWorld, lightDir), 0.0);
        intensity /= (distance(aPos, orbPosition) * 0.1);
    } else {
        intensity = 0.0;
    }

    // TODO: Make changes here for part b, c, d
  	// HINT: INTENSITY IS CALCULATED BY TAKING THE DOT PRODUCT OF THE NORMAL AND LIGHT DIRECTION VECTORS\

    // Multiply each vertex by the model matrix to get the world position of each vertex, 
    // then the view matrix to get the position in the camera coordinate system, 
    // and finally the projection matrix to get final vertex position
    
    gl_Position = projectionMatrix * viewMatrix * modelMatrix * vec4(position, 1.0);
}
