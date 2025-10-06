package plib.common.structs;

class Grid<T>
{
	public var wid(default, null):Int;
	public var hei(default, null):Int;

	public var grid:Array<T>;

	public function new(wid:Int, hei:Int, generator:(x:Int, y:Int) -> T)
	{
		this.grid = [];
		this.wid = wid;
		this.hei = hei;

		if (generator == null)
		{
			throw 'grid must have a generator';
		}

		for (y in 0...hei)
		{
			for (x in 0...wid)
			{
				grid.push(generator(x, y));
			}
		}
	}

	public inline function inbounds(x:Int, y:Int)
	{
		return x >= 0 && y >= 0 && x < wid && y < hei;
	}

	public inline function get(x:Int, y:Int)
	{
		return grid[flatten(x, y)];
	}

	public inline function set(x:Int, y:Int, val:T)
	{
		return grid[flatten(x, y)] = val;
	}

	private inline function flatten(x:Int, y:Int)
	{
		return y * wid + x;
	}
}
