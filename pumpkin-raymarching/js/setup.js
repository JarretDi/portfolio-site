/**
 * UBC CPSC 314
 * Assignment 3 Template setup
 */
import * as THREE from './three.module.js';
import { OBJLoader } from './OBJLoader.js';
import { OrbitControls } from './OrbitControls.js';
import { GLTFLoader } from './GLTFLoader.js';

/**
 * Sets up the THREE.js WebGL renderer and canvas
 */
function setup() {
    // Check WebGL Version
    if (!WEBGL.isWebGL2Available()) {
        document.body.appendChild(WEBGL.getWebGL2ErrorMessage());
    }

    // Get the canvas element and its drawing context from the HTML document.
    const canvas = document.getElementById('webglcanvas');
    const context = canvas.getContext('webgl2');

    // Construct a THREEjs renderer from the canvas and context.
    const renderer = new THREE.WebGLRenderer({ antialias: true, canvas, context });
    renderer.setClearColor(0X80CEE1); // blue background colour
    // renderer.autoClearColor = false;3
    
    return {
        renderer,
        canvas,
    };
}

/**
 * Creates a basic scene and returns necessary objects
 * to manipulate the scene, camera and render context.
 */
function createScene(canvas, renderer) {
  // Create THREE.js scene
  const scene = new THREE.Scene();

  // Set up the camera.
  const camera = new THREE.PerspectiveCamera(30.0, 1.0, 0.1, 1000.0); // view angle, aspect ratio, near, far
  camera.position.set(0.0, 30.0, 80.0);
  camera.lookAt(scene.position);
  scene.add(camera);

  // Setup orbit controls for the camera.
  const controls = new OrbitControls(camera, canvas);
  controls.screenSpacePanning = true;
  controls.damping = 0.2;
  controls.autoRotate = false;

  // Update projection matrix based on the windows size.
  function resize() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
  }
  window.addEventListener('resize', resize);
  resize();

  // World Coordinate Frame: other objects are defined with respect to it.
  const worldFrame = new THREE.AxesHelper(1);
  scene.add(worldFrame);

  return {
    scene,
    camera,
    worldFrame,
  };
}

function createRayMarchingScene(canvas, renderer) {
 // Create THREE.js scene
 const scene = new THREE.Scene();

 // Set up the camera.
 const camera = new THREE.OrthographicCamera(
    -1, // left
     1, // right
     1, // top
    -1, // bottom
    -1, // near,
     1, // far
    );
 scene.add(camera);

 function resize() {
    renderer.setSize(window.innerWidth, window.innerHeight);
}   
 window.addEventListener('resize', resize);
 resize();

 return {
   scene,
   camera,
 };
}

/**
 * Utility function that loads obj files using THREE.OBJLoader
 * and places them in the scene using the given callback `place`.
 * 
 * The variable passed into the place callback is a THREE.Object3D.
 */
async function loadGLTFAsync(files, postLoading) {
    const manager = new THREE.LoadingManager();
    manager.onProgress = function (item, loaded, total) {
        console.log("loading manager log: ", item, loaded, total);
    };

    const onProgress = function (xhr) {
        if (xhr.lengthComputable) {
            const percentComplete = xhr.loaded / xhr.total * 100.0;
            console.log(Math.round(percentComplete, 2) + '% downloaded');
        }
    };
    const loader = new GLTFLoader(manager);
    let models = await Promise.all(files.map(file => loader.loadAsync(file, onProgress)));
    postLoading(models);
}
// --------------------------------------------------------------

async function loadOBJAsync(files, postLoading) {
    const manager = new THREE.LoadingManager();
    manager.onProgress = function (item, loaded, total) {
        console.log("loading manager log: ", item, loaded, total);
    };

    const onProgress = function (xhr) {
        if (xhr.lengthComputable) {
            const percentComplete = xhr.loaded / xhr.total * 100.0;
            console.log(Math.round(percentComplete, 2) + '% downloaded');
        }
    };
    const loader = new OBJLoader(manager);
    let models = await Promise.all(files.map(file => loader.loadAsync(file, onProgress)));
    postLoading(models);
}

export {setup, createScene, createRayMarchingScene, loadGLTFAsync, loadOBJAsync};