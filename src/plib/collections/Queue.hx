package plib.collections;

/** Fixed-capacity FIFO ring buffer. Use it when capacity is known and allocations should stay stable. **/
class Queue<T>
{
	var vector:haxe.ds.Vector<T>;
	var front = 0;
	var end = 0;
	var count = 0;

	/** Creates an empty queue that can hold exactly `size` items. **/
	public function new(size:Int)
	{
		vector = new haxe.ds.Vector(size);
	}

	/** Removes every item without changing capacity. **/
	public function clear()
	{
		vector = new haxe.ds.Vector(vector.length);
		front = 0;
		end = 0;
		count = 0;
	}

	/** Returns the next item without removing it, or `null` when empty. **/
	public inline function peek()
	{
		if (isEmpty())
			return null;
		return vector.get(front);
	}

	/** Inserts at the front; throws when the queue is full. **/
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

	/** Appends at the back; throws when the queue is full. **/
	public function enqueue(item:T)
	{
		if (isFull())
			throw "Queue is full";

		vector.set(end, item);
		count++;
		end = (end + 1) % vector.length;
	}

	/** Removes and returns the front item, or `null` when empty. **/
	public function dequeue():T
	{
		if (isEmpty())
			return null;

		var r = vector.get(front);

		vector.set(front, null);
		front = (front + 1) % vector.length;
		count--;

		return r;
	}

	/** Removes the first equal item while preserving order. **/
	public function remove(item:T):Bool
	{
		var removed = false;
		var originalCount = count;

		for (_ in 0...originalCount)
		{
			var queuedItem = dequeue();
			if (!removed && queuedItem == item)
			{
				removed = true;
				continue;
			}

			enqueue(queuedItem);
		}

		return removed;
	}

	/** Returns capacity, not the current item count. **/
	public inline function size()
	{
		return vector.length;
	}

	/** Reports whether at least one item is queued. **/
	public inline function any()
	{
		return count > 0;
	}

	/** Reports whether the queue has reached capacity. **/
	public inline function isFull()
	{
		return count == vector.length;
	}

	/** Returns the number of currently queued items. **/
	public inline function getCount()
	{
		return count;
	}

	/** Reports whether no items are queued. **/
	public inline function isEmpty()
	{
		return count == 0;
	}
}
