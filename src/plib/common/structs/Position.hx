package plib.common.structs;

abstract Position({x:Float, y:Float})
{
	public var x(get, set):Int;
	public var y(get, set):Int;
	public var xf(get, set):Float;
	public var yf(get, set):Float;

	public static function distance(first:Position, other:Position)
	{
		final dx = first.x - other.x;
		final dy = first.x - other.y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	inline function get_xf()
	{
		return this.x;
	}

	inline function get_yf()
	{
		return this.y;
	}

	inline function set_xf(val:Float)
	{
		return this.x = val;
	}

	inline function set_yf(val:Float)
	{
		return this.y = val;
	}

	inline function get_x()
	{
		return Std.int(this.x);
	}

	inline function get_y()
	{
		return Std.int(this.y);
	}

	inline function set_x(val:Int)
	{
		this.x = val;
		return x;
	}

	inline function set_y(val:Int)
	{
		this.y = val;
		return y;
	}

	public function new(x:Float, y:Float, ?id:Int)
	{
		this = {x: x, y: y};
	}

	public function inverse()
	{
		return new Position(this.x * -1, this.y * -1);
	}

	@:op(a == b)
	function op_is(pos:Position)
	{
		return pos.x == this.x && pos.y == this.y;
	}

	@:op(a != b)
	function op_not(pos:Position)
	{
		return !(this.x == pos.x && this.y == pos.y);
	}

	@:op(a + b)
	function op_add(pos:Position):Position
	{
		return new Position(this.x + pos.x, this.y + pos.y);
	}
}
