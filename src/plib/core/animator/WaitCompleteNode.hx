package plib.core.animator;

class WaitCompleteNode extends AnimatorNode
{
	var fn:Void->Bool;

	public function new(fn:Void->Bool)
	{
		super();
		this.fn = fn;
	}

	override function isComplete():Bool
	{
		return fn();
	}
}
