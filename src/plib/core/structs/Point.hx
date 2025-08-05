package core.structs;

abstract Point({x:Float, y:Float})
{
	public var x(get, set):Float;
	public var y(get, set):Float;

	public static function distance(first:Point, other:Point)
	{
		final dx = first.x - other.x;
		final dy = first.x - other.y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	inline function get_x()
	{
		return this.x;
	}

	inline function get_y()
	{
		return this.y;
	}

	inline function set_x(val:Float)
	{
		return this.x = val;
	}

	inline function set_y(val:Float)
	{
		return this.y = val;
	}

	public function new(x:Float, y:Float)
	{
		this = {x: x, y: y};
	}

	public function lerp(point:Point, t:Float)
	{
		return new Point(Tween.lerp(this.x, point.x, t), Tween.lerp(this.y, point.y, t));
	}

	public function inverse()
	{
		return new Point(this.x * -1, this.y * -1);
	}

	@:op(a == b)
	function op_is(pos:Point)
	{
		return pos.x == this.x && pos.y == this.y;
	}

	@:op(a != b)
	function op_not(pos:Point)
	{
		return !(this.x == pos.x && this.y == pos.y);
	}

	@:op(a + b)
	function op_add(pos:Point):Point
	{
		return new Point(this.x + pos.x, this.y + pos.y);
	}
}
