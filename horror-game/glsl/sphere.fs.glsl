uniform bool orbLightOn;

void main() {

 	// TODO: Set final rendered color here
    if (orbLightOn) {
        gl_FragColor = vec4(0.8, 0.7, 0.0, 1.0);
    } else {
        gl_FragColor = vec4(0.1, 0.1, 0.0, 1.0);
    }
}
