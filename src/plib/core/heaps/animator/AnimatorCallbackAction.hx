package core.heaps.animator;

class AnimatorCallbackAction implements IAnimatorAction
{
	public var time(default, null):Float = 0;
	public var dir:Int = 1;

	private var callback:Void->Void;

	public function new(callback:Void->Void)
	{
		this.callback = callback;
	}

	public function start()
	{
		this.callback();
	}

	public function update(r:Float) {}
}
