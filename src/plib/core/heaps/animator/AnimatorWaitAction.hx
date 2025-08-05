package core.heaps.animator;

class AnimatorWaitAction implements IAnimatorAction
{
	public var time(default, null):Float;
	public var dir:Int;

	public function new(time:Float)
	{
		this.time = time;
	}

	public function start() {}

	public function update(r:Float) {}
}
