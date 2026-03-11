package plib.common.animator;

class CallbackNode extends AnimatorNode
{
	private var cb:Void->Void;

	public function new(fn:Void->Void)
	{
		super();
		cb = fn;
	}

	override function callback()
	{
		super.callback();
    
		if (cb != null)
		{
			cb();
		}
	}
}
