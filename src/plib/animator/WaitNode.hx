package plib.animator;

import plib.engine.Frame;

/** Timeline delay that completes after accumulating the requested frame time. **/
class WaitNode extends AnimatorNode
{
	private final seconds:Float;
	private var elapsed:Float = 0;

	/** Creates a non-negative delay in seconds. **/
	public function new(seconds:Float)
	{
		if (seconds < 0)
			throw 'Wait duration cannot be negative.';
		this.seconds = seconds;
	}

	override function update(frame:Frame)
		elapsed += frame.dt;

	/** Reports whether the elapsed duration reached the requested delay. **/
	public function completed():Bool
		return elapsed >= seconds;
}
