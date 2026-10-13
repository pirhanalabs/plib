package plib.animator;

class FnNode extends AnimatorNode
{
	private final callback:Void->Void;
	private var invoked:Bool = false;

	/** 
		Wraps one non-null callback. It does not consume an animation frame. 
	**/
	public function new(callback:Void->Void)
	{
		if (callback == null)
			throw 'Animator function cannot be null.';
		this.callback = callback;
	}

	override function prepare()
	{
		invoked = true;
		callback();
	}

	public function completed():Bool
		return invoked;
}
