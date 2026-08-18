package plib.animator;

/** Zero-duration timeline action that runs as soon as its parent prepares it. **/
class FnNode extends AnimatorNode
{
	private final callback:Void->Void;
	private var invoked:Bool = false;

	/** Wraps one non-null callback; it does not consume an animation frame. **/
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

	/** Reports whether the callback has run. **/
	public function completed():Bool
		return invoked;
}
