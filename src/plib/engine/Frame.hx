package plib.engine;

class Frame
{
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

	@:allow(plib.engine.IApplication)
	private function new() {}

	@:allow(plib.engine.IApplication)
	private function update()
	{
		dt = hxd.Timer.elapsedTime;
		fps = hxd.Timer.fps();
		tmod = hxd.Timer.tmod;

		frames++;
		elapsed += dt;
	}
}
