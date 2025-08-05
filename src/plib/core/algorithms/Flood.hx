package plib.core.algorithms;

import plib.core.structs.Matrix;
import plib.core.structs.Position;
import plib.core.structs.Queue;

class Flood
{
	public var validator:(Int, Int) -> Bool;

	var queue:Queue<Position>;
	var matrix:Matrix<Int>;

	public function new() {}

	public function flood(starts:Array<Position>, matrix:Matrix<Int>)
	{
		this.matrix = matrix;

		for (i in 0...matrix.size)
			matrix.data[i] = -1;

		queue = new Queue(128);

		for (pos in starts)
		{
			queue.enqueue(pos);
			setMark(pos.x, pos.y, 0);
		}

		runflood();
	}

	function runflood()
	{
		while (queue.any())
		{
			var cur = queue.dequeue();
			var mark = calcMark(cur.x, cur.y);
			spread(cur.x, cur.y, mark);
		}
	}

	inline function calcMark(x:Int, y:Int)
	{
		return 1 + getMark(x, y);
	}

	inline function getMark(x:Int, y:Int)
	{
		return matrix.get(x, y);
	}

	inline function setMark(x:Int, y:Int, mark:Int)
	{
		return matrix.set(x, y, mark);
	}

	function spread(x:Int, y:Int, mark:Int)
	{
		processIfValid(x, y + 1, mark);
		processIfValid(x, y - 1, mark);
		processIfValid(x + 1, y, mark);
		processIfValid(x - 1, y, mark);
	}

	function processIfValid(x:Int, y:Int, mark:Int)
	{
		if (positionValid(x, y))
		{
			process(x, y, mark);
		}
	}

	function process(x:Int, y:Int, mark:Int)
	{
		setMark(x, y, mark);
		queue.enqueue(new Position(x, y));
	}

	inline function positionValid(x:Int, y:Int)
	{
		if (validator != null && !validator(x, y))
			return false;

		return matrix.inbounds(x, y) && matrix.get(x, y) == -1;
	}
}
