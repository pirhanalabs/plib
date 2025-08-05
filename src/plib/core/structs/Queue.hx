package core.structs;

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

	public function peek()
	{
		return vector.get(front);
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

	public function size()
	{
		return vector.length;
	}

	public function any()
	{
		return count > 0;
	}

	public function isFull()
	{
		return count == vector.length;
	}

	public function getCount()
	{
		return count;
	}

	public function isEmpty()
	{
		return count == 0;
	}

	public function iterator()
	{
		return vector.toArray().iterator();
	}
}
