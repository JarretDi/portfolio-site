/*
 * UBC CPSC 314, Vsept2025
 * Assignment 1 Template
 */

// Setup and return the scene and related objects.
// You should look into js/setup.js to see what exactly is done here.
const {
  renderer,
  scene,
  camera,
  worldFrame,
  controls,
  minVec,
  maxVec,
} = setup();

/////////////////////////////////
//   YOUR WORK STARTS BELOW    //
/////////////////////////////////

// Initialize uniform
const orbPosition = { type: 'v3', value: new THREE.Vector3(0.0, 7.0, 0.0) };
// TODO: Create uniform variable for the radius of the orb and pass it into the shaders,
// you will need them in the latter part of the assignment
const orbRadius = { type: 'float', value : 0.5};
const orbLightOn = { type: 'bool', value : true};
let lightBattery = 100.0;
let flickering = false;
let flickerFrames = 0;
let gameOver = false;

// Materials: specifying uniforms and shaders
// Diffuse texture map (this defines the main colors of the boxing glove)
const gloveColorMap = new THREE.TextureLoader().load('images/boxing_gloves_texture.png');
const boxingGloveMaterial = new THREE.MeshStandardMaterial({
  map: gloveColorMap,
});
const armadilloMaterial = new THREE.ShaderMaterial({
    uniforms: {
        orbPosition: orbPosition,
        orbRadius: orbRadius,
        orbLightOn: orbLightOn
    }
});
const sphereMaterial = new THREE.ShaderMaterial({
    uniforms: {
        orbLightOn: orbLightOn,
    }
});

// Load shaders.
const shaderFiles = [
  'glsl/armadillo.vs.glsl',
  'glsl/armadillo.fs.glsl',
  'glsl/sphere.vs.glsl',
  'glsl/sphere.fs.glsl'
];

new THREE.SourceLoader().load(shaderFiles, function (shaders) {
  armadilloMaterial.vertexShader = shaders['glsl/armadillo.vs.glsl'];
  armadilloMaterial.fragmentShader = shaders['glsl/armadillo.fs.glsl'];

  sphereMaterial.vertexShader = shaders['glsl/sphere.vs.glsl'];
  sphereMaterial.fragmentShader = shaders['glsl/sphere.fs.glsl'];
})

// Load and place the Armadillo geometry
// Look at the definition of loadOBJ to familiarize yourself with how each parameter
// affects the loaded object.
let armadillo;
loadAndPlaceOBJ('obj/armadillo.obj', armadilloMaterial, function (armadilloInit) {
  armadillo = armadilloInit;
  armadillo.position.set(0.0, 5.3, -15.0);
  armadillo.rotation.y = Math.PI;
  armadillo.scale.set(0.1, 0.1, 0.1);
  armadillo.parent = worldFrame;
  scene.add(armadillo);
});

// TODO: Add the hat to the scene on top of the Armadillo similar to how the Armadillo
// is added to the scene
loadAndPlaceOBJ('obj/boxing_glove.obj', boxingGloveMaterial, function (boxing_glove) {
    boxing_glove.position.set(-55, 70, -43);
    boxing_glove.rotateY(Math.PI * -0.43);
    boxing_glove.rotateX(Math.PI * 0.5);
    boxing_glove.scale.set(12, 12, 12);
    boxing_glove.parent = worldFrame;
    armadillo.add(boxing_glove);
});

loadAndPlaceOBJ('obj/boxing_glove.obj', boxingGloveMaterial, function (boxing_glove) {
    boxing_glove.position.set(53, 74, -28);
    boxing_glove.rotateY(Math.PI * 0.6);
    boxing_glove.rotateX(Math.PI * -0.69);
    boxing_glove.rotateZ(Math.PI * -0.30);
    boxing_glove.scale.set(-12, -12, -12);
    boxing_glove.parent = worldFrame;
    armadillo.add(boxing_glove);
});

// Create the sphere geometry
// https://threejs.org/docs/#api/en/geometries/SphereGeometry
// TODO: Make the radius of the orb a variable
const sphereGeometry = new THREE.SphereGeometry(orbRadius.value, 32.0, 32.0);
const sphere = new THREE.Mesh(sphereGeometry, sphereMaterial);
sphere.position.set(orbPosition.value.x, orbPosition.value.y, orbPosition.value.z);
scene.add(sphere);
sphere.parent = worldFrame;

const sphereLight = new THREE.PointLight(0xffffff, 1, 100);
scene.add(sphereLight);

const batteryGeometry = new THREE.BoxGeometry(1, 1, 1);
const batteryMaterial = new THREE.MeshStandardMaterial({ color: 0xffff00 });
const batteries = [];

const offset = new THREE.Vector3(0, 5, 10);

// will be called when light flickers
function teleportArmadillo() {
    if (!armadillo) return;
    const toOrb = new THREE.Vector3().subVectors(armadillo.position, orbPosition.value);
    const dist = toOrb.length();

    // Pick random point in a circle around the orb
    const angle = Math.random() * Math.PI * 2;
    const offset = new THREE.Vector3(
        Math.cos(angle) * dist,
        0,
        Math.sin(angle) * dist
    );

    armadillo.position.set(
        orbPosition.value.x + offset.x,
        armadillo.position.y,
        orbPosition.value.z + offset.z
    );
    armadillo.position.clamp(minVec, maxVec);
}

// Listen to keyboard events.
const keyboard = new THREEx.KeyboardState();
function checkKeyboard() {
  let cameraDir = new THREE.Vector3();
  camera.getWorldDirection(cameraDir);
  cameraDir.y = 0;
  cameraDir.normalize();
  const moveDir = new THREE.Vector3();

  if (keyboard.pressed("W"))      moveDir.add(cameraDir);
  else if (keyboard.pressed("S")) moveDir.sub(cameraDir);
  
  // this will give the vector to the right, just uses cameraDir to save space
  cameraDir.cross(new THREE.Vector3(0, 1, 0)).normalize();

  if (keyboard.pressed("A"))      moveDir.sub(cameraDir);
  else if (keyboard.pressed("D")) moveDir.add(cameraDir);

  if (moveDir.length() > 0) {
    moveDir.normalize().multiplyScalar(0.3);
    orbPosition.value.add(moveDir);
  }

  orbPosition.value.clamp(minVec, maxVec);

  if (true && (lightBattery > 0)) {
    if (flickerFrames <= 0) {
        // light is more likely to flicker, and flickers for longer on lower battery
        const batteryFactor = 1.0 - lightBattery / 100;
        flickering = Math.random() < Math.min(Math.pow(batteryFactor, 3), 0.01);

        if (flickering) {
            const minFrames = 2;
            const maxFrames = 1 + Math.floor(batteryFactor * 20);
            flickerFrames = minFrames + Math.floor(Math.random() * maxFrames);
            teleportArmadillo();
        }
      } else {
        flickerFrames--;
    }
    orbLightOn.value = true;
    if (flickering) {
        sphereLight.color.lerp(new THREE.Color(0x555511), 0.2);
        orbLightOn.value = false;
    } else {
        sphereLight.color.lerp(new THREE.Color(0xddddaa), 0.2);
    }
    
    lightBattery -= 0.1;
  } else {
    orbLightOn.value = false;
    sphereLight.color.lerp(new THREE.Color(0x000000), 0.3);
  }

  // The following tells three.js that some uniforms might have changed
  armadilloMaterial.needsUpdate = true;
  sphereMaterial.needsUpdate = true;

  // Move the sphere light in the scene. This allows the floor to reflect the light as it moves.
  sphereLight.position.set(orbPosition.value.x, orbPosition.value.y, orbPosition.value.z);

  sphere.position.copy(orbPosition.value);
}

function updateBatteryDisplay() {
    const batteryBar = document.getElementById("battery-level");
    batteryBar.style.width = `${lightBattery}%`;

    if (lightBattery > 50) { // green
        batteryBar.style.backgroundColor = "#0f0";
    } else if (lightBattery > 20) { // yellow
        batteryBar.style.backgroundColor = "#ff0";
    } else { // red
        batteryBar.style.backgroundColor = "#f00";
    }
}

function spawnBattery(position) {
    const battery = new THREE.Mesh(batteryGeometry, batteryMaterial);
    battery.position.copy(position);
    scene.add(battery);
    batteries.push(battery);
}

function checkBatteryCollision() {
    for (let i = 0; i < batteries.length; i++) {
        const battery = batteries[i];
        if (battery.position.distanceTo(orbPosition.value) < 2) {
            lightBattery = Math.min(lightBattery + 20, 100);

            scene.remove(battery);
            batteries.splice(i, 1);
        }
    }
}

let startTime = Date.now();
let timeSurvived = 0;

function updateTimeDisplay() {
    const now = Date.now();
    timeSurvived = (now - startTime) / 1000;

    document.getElementById("timeSurvived").innerText = 
        `Time Survived: ${timeSurvived.toFixed(2)}s`;
}

const followDistance = 15;
const followHeight = 2;

// want the camera to be behind the orb at a certain distance, but still be within room bounds
function updateCamera() {
    // get orb forward
    const forward = new THREE.Vector3();
    camera.getWorldDirection(forward);
    forward.y = 0;
    forward.normalize();

    const desiredOffset = forward.multiplyScalar(-followDistance);
    desiredOffset.y = followHeight;

    const desiredCameraPosition = orbPosition.value.clone().add(desiredOffset);

    let offsetFromOrb = desiredCameraPosition.clone().sub(orbPosition.value);

    let scaleX = 1, scaleY = 1, scaleZ = 1;

    // find the smallest bound that goes outside of the room range, then divide by it
    if (offsetFromOrb.x + orbPosition.value.x > maxVec.x) scaleX = (maxVec.x - orbPosition.value.x) / offsetFromOrb.x;
    if (offsetFromOrb.x + orbPosition.value.x < minVec.x) scaleX = (minVec.x - orbPosition.value.x) / offsetFromOrb.x;

    if (offsetFromOrb.y + orbPosition.value.y > maxVec.y) scaleY = (maxVec.y - orbPosition.value.y) / offsetFromOrb.y;
    if (offsetFromOrb.y + orbPosition.value.y < minVec.y) scaleY = (minVec.y - orbPosition.value.y) / offsetFromOrb.y;

    if (offsetFromOrb.z + orbPosition.value.z > maxVec.z) scaleZ = (maxVec.z - orbPosition.value.z) / offsetFromOrb.z;
    if (offsetFromOrb.z + orbPosition.value.z < minVec.z) scaleZ = (minVec.z - orbPosition.value.z) / offsetFromOrb.z;

    const scale = Math.min(scaleX, scaleY, scaleZ, 1);

    offsetFromOrb.multiplyScalar(scale);

    camera.position.copy(orbPosition.value.clone().add(offsetFromOrb));

    // Update controls so changes take effect
    controls.target.copy(orbPosition.value);
    controls.update();
}

function checkGameOver() {
    if (orbPosition.value.distanceTo(armadillo.position) <= 2.0) {
        document.getElementById("game-over").style.display = "block";
        gameOver = true;
    }
}

// Setup update callback
function update() {
  checkKeyboard();

  updateBatteryDisplay();

  updateTimeDisplay();

  updateCamera();
  
  if (Math.random() < 0.005 && batteries.length < 3 && lightBattery < 80) {
    let spawnLocation = new THREE.Vector3();
    spawnLocation.x = (2 * (Math.random() - 0.5) * maxVec.x);
    spawnLocation.y = orbPosition.value.y;
    spawnLocation.z = (2 * (Math.random() - 0.5) * maxVec.z);
    spawnBattery(spawnLocation);
  }

  checkBatteryCollision();

  // Move the armadillo towards the player if the light is off, or the light flickers
  if (armadillo) {
    checkGameOver();
    if (!orbLightOn.value && timeSurvived > 3 ) {
        const target = new THREE.Vector3(orbPosition.value.x, armadillo.position.y, orbPosition.value.z);
        
        const toTarget = target.clone().sub(armadillo.position);
        const distance = toTarget.length();

        const speed = 0.40; // slightly faster than player
        if (distance > speed) {
            toTarget.normalize().multiplyScalar(speed - (Math.random() / 10));
            armadillo.position.add(toTarget);
        } else {
            // Close enough: snap to target
            armadillo.position.copy(target);
        }
        armadillo.lookAt(target);
        armadillo.rotation.y += Math.PI;
    }
  }

  // Requests the next update call, this creates a loop
  if (!gameOver) requestAnimationFrame(update);
  renderer.render(scene, camera);
}

// Start the animation loop.
update();
