// The value of the "varying" variable is interpolated between values computed in the vertex shader
// The varying variable we passed from the vertex shader is identified by the 'in' classifier
in float intensity;
in vec3 aPos;

uniform vec3 orbPosition;
uniform float orbRadius;

void main() {
    if (distance(aPos, orbPosition) > 6.0 * orbRadius) {
        gl_FragColor = vec4(intensity*vec3(0.8,0.7,0.4), 1.0); 
    } else {
        gl_FragColor = vec4(intensity*vec3(1.0,0.2,0.1), 1.0); 
    }
}
