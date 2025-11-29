# Assignment 1

## Student Info
Jarret Diep
75824532
jdiep01

## General Description
My part 2 of the assignment turns the scene into a fully-fledged horror game. You play as a ball trapped in a dark room, being chased by a boxing-glove wielding armadillo. The goal is to survive for as long as possible. But you aren't defenseless; holding Space you activate your flashlight, which freezes the armadillo in place. However, the flashlight has limited battery, and while additional batteries occasionally spawn in the room, the light is prone to flickering, making it easy to lost track of the armadillo. In the end, it's not a matter of *if* you'll get caught, but *when*.

## Controls
* WASD - move forward, back, left and right with respect to the direction of the camera
* Space - turns on your light while its held
* Left mouse drag - turns the camera

## List of added features:
* Made the armadillo move towards the player at a rate slightly faster than the player can move
	* Whenever the light flickers, the armadillo teleports to a random location in the room with the same distance to the player
* Changed the camera to follow the orb, third person camera style
	* Experimented with OrbitControls.js to figure out how it worked, and enabled / disabled features where appropriate
	* Additionally had it zoom in when necessary to stay inside room bounds (so that it doesn't clip through walls and block view)
	* Needed to pass orbital controls to the update loop to do this
* Changed player movement to move relative to the camera's direction
* Used the given floor object to create a room by duplicating, scaling, rotating and then translating it to make walls and a ceiling
	* Clamped all objects so that they can't leave the room. Did this by modifying setup() to pass the min/max coords of the room
* Attached the boxing gloves to the armadillo so that they move alongside it
	* Small note: sometimes the armadillo is late in loading, and since its asynchronous the boxing gloves attempt to load before it and fail since they need to be children of it. Don't know how to solve, but a refresh will work most of the time
* Created a new uniform, orbLightOn
	* Passed into armadillo's vertex shader to determine whether the armadillo should be lit
	* Passed into sphere's fragment shader to have different on/off colours
	* Randomly flickers sometimes for a short, random period of time (quantities increase as battery life lowers)
* Changed some colours to fit better with the atmosphere of the game:
	* Changed the point light colour to be a yellow tint (that gets darker when flickers happen, and turns off when not holding space)
	* Changed the armadillos skin to be blood red instead of teal when the orb is too close
	* Changed the ambient light to be weaker, darker and yellow
	* Changed the clear colour from sky blue to black
* Added some box geometries (batteries) that spawn randomly in the scene and have some basic collision detection to pick them up
* Added some basic responsive html elements as a HUD
	* Battery life in the top left that changes colour depending on remaining battery
	* Timer in the top right that keeps track of how long you've lived for
	* Game over screen that halts the render loop when triggered
* Removed the magnetizing orb feature as it didn't really fit in with the game
* Changed orb to use THREE.js builtin position w/ model matrix as doing it with the uniform was causing odd bugs with the camera

## Sources / References
* https://learnopengl.com/ - read prior to taking this course. Not directly referenced during this assignment, but learned concepts may have influenced work
* ChatGPT - used for syntax, troubleshooting and three.js basics