package plib.engine;

/** Application-owned timing snapshot passed through node updates each frame. **/
class Frame
{
	/** Multiplies `dt` and `tmod`; use for global slow motion, not pausing nodes. **/
	public var mod:Float = 1.0;

	/**
		the seconds since last frame.
	**/
	public var dt(default, null):Float;

	/**
		The current number of frames per second.
	**/
	public var fps(default, null):Float;

	/**
		modifier that shows real FPS relative to desired FPS. this allows
		for the game to be frame-rate independant. Use this whenever moving
		objects on the screen.

		tmod = 1, game is running at desired speed.
		tmod < 1, game is running faster than desired speed.
		tmod > 1, game is running slower than desired speed.
	**/
	public var tmod(default, null):Float;

	/** 
		the seconds since the game has been running 
	**/
	public var elapsed(default, null):Float = 0;

	/** 
		number of frames since the game start 
	**/
	public var frames(default, null):Float = 0;

	/** Creates an empty snapshot; `Application` normally owns and updates it. **/
	public function new() {}

	/** Samples the Heaps timer and advances elapsed time and frame count. **/
	public function update()
	{
		dt = hxd.Timer.elapsedTime * mod;
		fps = hxd.Timer.fps();
		tmod = hxd.Timer.tmod * mod;

		frames++;
		elapsed += dt;
	}
}
