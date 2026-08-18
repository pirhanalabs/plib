package plib.animator;

import plib.engine.Frame;

/** Calls `callback(target, ratio)` during postupdate until ratio reaches one. **/
class AnimationNode<T> extends AnimatorNode
{
	private final target:T;
	private final callback:(target:T, ratio:Float) -> Void;
	private final seconds:Float;
	private var elapsed:Float = 0;
	private var done:Bool = false;

	/** Creates a timed animation; zero seconds invokes ratio `1` during preparation. **/
	public function new(seconds:Float, target:T, callback:(target:T, ratio:Float) -> Void)
	{
		if (seconds < 0)
			throw 'Animation duration cannot be negative.';
		this.seconds = seconds;
		this.target = target;
		this.callback = callback;
	}

	override function prepare()
	{
		if (seconds == 0)
		{
			done = true;
			callback(target, 1);
		}
	}

	override function update(frame:Frame)
	{
		if (!done)
			elapsed = Math.min(seconds, elapsed + frame.dt);
	}

	override function postupdate()
	{
		if (done)
			return;
		var ratio = elapsed / seconds;
		if (ratio >= 1)
			done = true;
		callback(target, ratio);
	}

	/** Reports whether the final ratio has been delivered. **/
	public function completed():Bool
		return done;
}
