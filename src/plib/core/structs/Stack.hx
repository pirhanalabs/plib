package core.structs;

class Stack<T>
{
	var vector:haxe.ds.Vector<T>;
	var count = 0;

	/**
		Lifo queue.
	**/
	public function new(size:Int)
	{
		vector = new haxe.ds.Vector(size);
	}

	public function peek()
	{
		return vector.get(count - 1);
	}

	public function push(item:T)
	{
		if (isFull())
			throw 'limit bypassed';
		vector.set(count, item);
		count++;
	}

	public function pop():T
	{
		if (count == 0)
			return null;

		count--;
		var r = vector.get(count);
		vector.set(count, null);
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
