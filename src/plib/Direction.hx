package plib;

class Direction
{
	public static final N:Direction = new Direction(0, 'north', 0, -1, 1);
	public static final W:Direction = new Direction(1, 'west', -1, 0, 2);
	public static final S:Direction = new Direction(2, 'south', 0, 1, 4);
	public static final E:Direction = new Direction(3, 'east', 1, 0, 8);
	public static final NW:Direction = new Direction(4, 'north-west', -1, -1, 16);
	public static final NE:Direction = new Direction(5, 'north-east', 1, -1, 32);
	public static final SW:Direction = new Direction(6, 'south-west', -1, 1, 64);
	public static final SE:Direction = new Direction(7, 'south-east', 1, 1, 128);

	public static final D4:haxe.ds.ReadOnlyArray<Direction> = [N, W, S, E];
	public static final C4:haxe.ds.ReadOnlyArray<Direction> = [NW, NE, SW, SE];
	public static final D8:haxe.ds.ReadOnlyArray<Direction> = [N, W, S, E, NW, NE, SW, SE];

	public var id(default, null):Int;
	public var name(default, null):String;
	public var bm(default, null):Int;
	public var dx(default, null):Int;
	public var dy(default, null):Int;

	public static function fromDeltas(dx:Float, dy:Float)
	{
		var sx = MathTools.sign(dx);
		var sy = MathTools.sign(dy);
		return D8.filter(d -> d.dx == sx && d.dy == sy)[0];
	}

	private function new(id:Int, name:String, dx:Int, dy:Int, bm:Int)
	{
		this.id = id;
		this.name = name;
		this.bm = bm;
		this.dx = dx;
		this.dy = dy;
	}

	public inline function getBitmask():Int
	{
		return 1 << id;
	}

	public inline function getReverse():Direction
	{
		var m = Math.floor(this.id / 4) * 4;
		return D8[m + (this.id + 2) % 4];
	}
}
