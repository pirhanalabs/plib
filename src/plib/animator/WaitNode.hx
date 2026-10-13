package plib.animator;

import plib.engine.Frame;

class WaitNode extends AnimatorNode
{
	private final seconds:Float;
	private var elapsed:Float = 0;

	public function new(seconds:Float)
	{
		if (seconds < 0)
		{
			seconds = 0;
		}
		this.seconds = seconds;
	}

	override function update(frame:Frame)
	{
		elapsed += frame.dt;
	}

	public function completed():Bool
	{
		return elapsed >= seconds;
	}
}
