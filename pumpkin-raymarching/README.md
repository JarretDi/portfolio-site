# Assignment 3 Feature Extension - Perlin and Pumpkins

All functionality is in the fragment shader extension.fs.glsl
Press 9 to view scene and A, D to rotate camera

- Terrain:
 - Added a FBM + Perlin Noise based terrain generator
 - Customizable Amplititude, Frequency and Octave count
 - Added a day and night cycle to visualize shadows on the terrain
- Pumpkin:
 - Added more detail to pumpkin with RibbedSphere sinusoid SDF
 - Refactored Pumpkin SDF with arbitrary position and rotation and placed a couple in scene