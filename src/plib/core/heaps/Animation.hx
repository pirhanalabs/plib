package core.heaps;

class Animation extends h2d.Drawable
{
	public var loop:Bool = true;
	public var pause:Bool = false;
	public var index(default, null):Int;

	var frames:Array<h2d.Tile>;
	public var frameDuration:Float;

	/**
		Animation class unbound by application time.
		To update, call update(stime);

		Note: using the same timer and frame duration for all animations
		will sync them together.

		you can pause an animation individually using pause.
	**/
	public function new(frames:Array<h2d.Tile>, frameDuration:Float = 0.15)
	{
		super(null);
		this.frames = frames;
		this.index = 0;
		this.frameDuration = frameDuration;
		this.pause = false;
		this.loop = true;
	}

	public function setFrames(frames:Array<h2d.Tile>)
	{
		var r = index / this.frames.length;
		this.frames = frames;
		updateRatio(r);
	}

	public function getKeyframe(stime:Float)
	{
		if (pause)
		{
			return index;
		}

		var total_time = frameDuration * frames.length;

		var t = loop ? stime % total_time : stime.clamp(0, total_time);
		return Math.floor(t * frames.length / total_time);
	}

	/** updates the current frame based on a ratio**/
	public function updateRatio(r:Float)
	{
		index = getKeyframe(frameDuration * frames.length * r);
	}

	/** updates the current frame based on a timer, in seconds.**/
	public function updateTime(stime:Float)
	{
		index = getKeyframe(stime);
	}

	override function draw(ctx:h2d.RenderContext)
	{
		super.draw(ctx);
		if (frames != null)
			emitTile(ctx, frames[index]);
	}
}
