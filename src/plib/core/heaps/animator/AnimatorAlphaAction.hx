package core.heaps.animator;

class AnimatorAlphaAction implements IAnimatorAction
{
	private var startAlpha:Float;
	private var add:Float;
	private var o:h2d.Object;
	private var easing:Float->Float;

	public var dir:Int;
	public var time(default, null):Float;

	public function new(o:h2d.Object, time:Float, add:Float, easing:Float->Float)
	{
		this.o = o;
		this.startAlpha = 0;
		this.dir = 0;
		this.time = time;
		this.add = add;
		this.easing = easing;
	}

	public function start()
	{
		this.startAlpha = o.alpha;
	}

	public function update(r:Float)
	{
		var ease = dir > 0 ? this.easing(r) : 1.0 - this.easing(1.0 - r);
		this.o.alpha = Tween.lerp(startAlpha, startAlpha + (add * dir), ease);
	}
}
