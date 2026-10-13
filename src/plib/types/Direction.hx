package plib.types;

/**
	One of the eight neighboring grid directions, or the stationary center.

	The underlying value packs the normalized x and y coordinates into separate
	bit pairs, following the same layout as `hxd.Direction`. `bitmask` exposes
	an independent flag for combining directional selections.
**/
enum abstract Direction(Int)
{
	public static final D4:Array<Direction> = [Top, Left, Right, Bottom];
	public static final D8:Array<Direction> = [TopLeft, Top, TopRight, Left, Right, BottomLeft, Bottom, BottomRight];

	var TopLeft = 0;
	var Top = 1;
	var TopRight = 2;
	var Left = 4;
	var Center = 5;
	var Right = 6;
	var BottomLeft = 8;
	var Bottom = 9;
	var BottomRight = 10;

	/** Horizontal unit offset: -1 for left, 1 for right, otherwise 0. **/
	public var dx(get, never):Int;

	/** Vertical unit offset: -1 for top, 1 for bottom, otherwise 0. **/
	public var dy(get, never):Int;

	/** Independent direction flag (`1 << index`), or 0 for `Center`. **/
	public var bitmask(get, never):Int;

	private inline function get_dx():Int
	{
		return (this & 3) - 1;
	}

	private inline function get_dy():Int
	{
		return (this >> 2) - 1;
	}

	private inline function get_bitmask():Int
	{
		var gridIndex = (this >> 2) * 3 + (this & 3);
		if (gridIndex == 4)
			return 0;
		return 1 << (gridIndex > 4 ? gridIndex - 1 : gridIndex);
	}

	/** Creates a direction from exact unit coordinates in the range -1 through 1. **/
	public static inline function from(x:Int, y:Int):Direction
	{
		if (x < -1 || x > 1 || y < -1 || y > 1)
			throw 'Direction coordinates must be between -1 and 1.';
		return cast((x + 1) | ((y + 1) << 2));
	}

	/** Creates a direction by reducing an arbitrary vector delta to its signs. **/
	public static inline function fromDelta(dx:Float, dy:Float):Direction
	{
		var x = dx < 0 ? -1 : dx > 0 ? 1 : 0;
		var y = dy < 0 ? -1 : dy > 0 ? 1 : 0;
		return from(x, y);
	}
}
