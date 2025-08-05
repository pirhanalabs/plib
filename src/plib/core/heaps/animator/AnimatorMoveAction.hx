package core.heaps.animator;

class AnimatorMoveAction implements IAnimatorAction
{
	public var time(default, null):Float;
	public var dir:Int;

	private var o:h2d.Object;
	private var x:Float;
	private var y:Float;

	private var sx:Float;
	private var sy:Float;

	private var easing:Float->Float;

	public function new(o:h2d.Object, time:Float, x:Float, y:Float, easing:Float->Float)
	{
		this.o = o;
		this.time = time;
		this.x = x;
		this.y = y;

		this.sx = 0;
		this.sy = 0;

		this.easing = easing;
		this.dir = 1;
	}

	public function start()
	{
		this.sx = o.x;
		this.sy = o.y;
	}

	public function update(r:Float)
	{
		var ease = dir > 0 ? this.easing(r) : 1.0 - this.easing(1.0 - r);
		this.o.x = Tween.lerp(sx, sx + (x * dir), ease);
		this.o.y = Tween.lerp(sy, sy + (y * dir), ease);
	}
}
