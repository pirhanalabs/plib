package plib.common.structs;

class Queue<T>
{
	var vector:haxe.ds.Vector<T>;
	var front = 0;
	var end = 0;
	var count = 0;

	/**
		Fifo queue.
	**/
	public function new(size:Int)
	{
		vector = new haxe.ds.Vector(size);
	}

	public function clear()
	{
		vector = new haxe.ds.Vector(vector.length);
		front = 0;
		end = 0;
		count = 0;
	}

	public inline function peek()
	{
		if (isEmpty())
			return null;
		return vector.get(front);
	}

	public function unshift(item:T)
	{
		if (isFull())
		{
			throw "Queue is full";
		}

		front = (front - 1 + vector.length) % vector.length;
		vector.set(front, item);
		count++;
	}

	public function enqueue(item:T)
	{
		vector.set(end, item);
		count++;
		end = (end + 1) % vector.length;
	}

	public function dequeue():T
	{
		if (front == end)
			return null;

		var r = vector.get(front);

		vector.set(front, null);
		front = (front + 1) % vector.length;
		count--;

		return r;
	}

	public inline function size()
	{
		return vector.length;
	}

	public inline function any()
	{
		return count > 0;
	}

	public inline function isFull()
	{
		return count == vector.length;
	}

	public inline function getCount()
	{
		return count;
	}

	public inline function isEmpty()
	{
		return count == 0;
	}

	public function iterator()
	{
		return vector.toArray().iterator();
	}
}
