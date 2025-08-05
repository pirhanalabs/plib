package plib.core.animator;

class WaitNode extends AnimatorNode
{
	var timeMax:Float;
	var timeCur:Float;

	public function new(stime:Float)
	{
		super();
		timeMax = stime;
		timeCur = 0;
	}

	override function update(frame:plib.engine.Frame)
	{
		timeCur += frame.dt;

		if (timeCur > timeMax)
		{
			timeCur = timeMax;
		}
	}

	override function isComplete():Bool
	{
		return timeCur >= timeMax;
	}
}
