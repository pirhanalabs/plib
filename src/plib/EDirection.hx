package plib;

/**
	Because Direction is not an enum itself(too complex for an enum),
	we use EDirection to map an enum to actual Direction implementation.

	This makes it so we dont have to type 'plib.Direction.myDir' every time, 
	or remember them, as enums have autocomplete for fields.

	Also, Direction uses cardinal directions, whereas this uses relative directions.
**/
enum abstract EDirection(Int)
{
	var Up = 0;
	var Lt = 1;
	var Dw = 2;
	var Rt = 3;

	var Up_Lt = 4;
	var Up_Rt = 5;
	var Dw_Lt = 6;
	var Dw_Rt = 7;

	public var x(get, never):Int;
	public var y(get, never):Int;
	public var bm(get, never):Int;
	public var name(get, never):String;

	public static function fromDelta(x:Int, y:Int)
	{
		return new EDirection(Direction.fromDeltas(x, y).id);
	}

	@:from
	public static function fromDirection(dir:Direction)
	{
		return new EDirection(dir.id);
	}

	public inline function new(val:Int)
	{
		this = val;
	}

	public inline function reverse()
	{
		return toDirection().getReverse().toEDir();
	}

	@:to
	public inline function toDirection():Direction
	{
		return Direction.D8[this];
	}

	inline function get_x()
	{
		return toDirection().dx;
	}

	inline function get_y()
	{
		return toDirection().dy;
	}

	inline function get_bm()
	{
		return toDirection().bm;
	}

	inline function get_name()
	{
		return toDirection().name;
	}
}
