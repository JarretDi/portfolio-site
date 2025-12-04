/*
 * UBC CPSC 314
 * Assignment 3 Template
 */
import { setup, createScene, createRayMarchingScene, loadGLTFAsync, loadOBJAsync } from './js/setup.js';
import * as THREE from './js/three.module.js';
import { SourceLoader } from './js/SourceLoader.js';
import { THREEx } from './js/KeyboardState.js';

// Setup the renderer
// You should look into js/setup.js to see what exactly is done here.
const { renderer, canvas } = setup();

// Uniforms - Pass these into the appropriate vertex and fragment shader files
const spherePosition = { type: 'v3', value: new THREE.Vector3(0.0, 0.0, 0.0) };

const ticks = { type: "f", value: 0.0 };
const resolution =  { type: 'v3', value: new THREE.Vector3() };

const rayMarchingMaterial = new THREE.ShaderMaterial({
  uniforms: {
    time: ticks,
    resolution: resolution,
    camPos: spherePosition
  }
});

const shaderFiles = [
  'glsl/raymarching.vs.glsl',
  'glsl/raymarching.fs.glsl',
];

new SourceLoader().load(shaderFiles, function (shaders) {
  rayMarchingMaterial.vertexShader = shaders['glsl/raymarching.vs.glsl'];
  rayMarchingMaterial.fragmentShader = shaders['glsl/raymarching.fs.glsl'];
});

const {scene, camera} = createRayMarchingScene(canvas, renderer);
const plane = new THREE.PlaneGeometry(2, 2);
scene.add(new THREE.Mesh(plane, rayMarchingMaterial));

// Listen to keyboard events.
const keyboard = new THREEx.KeyboardState();
function checkKeyboard() {
  if (keyboard.pressed("W"))
    spherePosition.value.z -= 0.3;
  else if (keyboard.pressed("S"))
    spherePosition.value.z += 0.3;

  if (keyboard.pressed("A"))
    spherePosition.value.x -= 0.3;
  else if (keyboard.pressed("D"))
    spherePosition.value.x += 0.3;
  
  const canvas = renderer.domElement;
  resolution.value.set(canvas.width, canvas.height, 1);

  rayMarchingMaterial.needsUpdate = true;
}

let clock = new THREE.Clock;

// Setup update callback
function update() {
  checkKeyboard();
  ticks.value += clock.getDelta();

  // Requests the next update call, this creates a loop
  requestAnimationFrame(update);
  renderer.render(scene, camera);
}

// Start the animation loop.
update();