package core.structs;

import core.structs.Direction.DirectionType;
import core.structs.Direction;

class Matrix<T>
{
	public final wid:Int;
	public final hei:Int;
	public final size:Int;

	public var data:Array<T>;

	/**
		Meant to be used primarily for algorithms using core types.
		For immutable objects, use pirhana.utils.Grid2D instead.
	**/
	public function new(wid:Int, hei:Int, def:T)
	{
		this.wid = wid;
		this.hei = hei;
		this.size = this.wid * this.hei;

		data = [for (_ in 0...size) def];
	}

	public function countSameNeighbors(x:Int, y:Int, type:DirectionType)
	{
		final val = get(x, y);
		if (val == null)
			return -1;

		var score = 0;
		var xx:Int = 0;
		var yy:Int = 0;

		for (dir in Direction.getDirs(type))
		{
			xx = x + dir.x;
			yy = y + dir.y;
			if (!inbounds(xx, yy))
			{
				score++;
				continue;
			}
			score += get(xx, yy) == val ? 1 : 0;
		}
		return score;
	}

	public function getId(id:Int)
	{
		return data[id];
	}

	public function setId(id:Int, val:T)
	{
		return data[id] = val;
	}

	public function get(x:Int, y:Int)
	{
		return getId(flatten(x, y));
	}

	public function set(x:Int, y:Int, val:T)
	{
		return setId(flatten(x, y), val);
	}

	function flatten(x:Int, y:Int)
	{
		return y * wid + x;
	}

	public function inbounds(x:Int, y:Int)
	{
		return x >= 0 && y >= 0 && x < wid && y < hei;
	}

	public function clone()
	{
		// maybe theres a better way than this.
		var matrix = new Matrix<T>(this.wid, this.hei, this.get(0, 0));
		matrix.data = this.data.copy();
		return matrix;
	}
}
