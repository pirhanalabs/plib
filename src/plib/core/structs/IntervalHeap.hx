package core.structs;

class IntervalHeap<T>
{
	var heap:Array<Null<T>>;
	var comparator:(T, T) -> Int;

	public function new(comparator:(T, T) -> Int)
	{
		this.heap = [];
		this.comparator = comparator;
	}

	public function size()
	{
		return heap.length >> 1;
	}

	public function any()
	{
		return heap.length != 0;
	}

	public function isEmpty()
	{
		return heap.length == 0;
	}

	public function insert(value:T)
	{
		heap.push(value);
		heap.push(value);
		balanceUp((heap.length >> 1) - 1);
	}

	public function getMin()
	{
		return isEmpty() ? null : heap[0];
	}

	public function getMax()
	{
		return isEmpty() ? null : heap[1];
	}

	public function removeMin()
	{
		if (isEmpty())
			return null;

		return remove(0);
	}

	public function removeMax()
	{
		if (isEmpty())
			return null;

		return remove(1);
	}

	function remove(pos:Int)
	{
		var val = heap[pos];

		if (heap.length == 2)
		{
			heap.pop();
			heap.pop();
		}
		else
		{
			heap[0] = heap[heap.length - 2];
			heap[1] = heap[heap.length - 1];
			heap.pop();
			heap.pop();
			balanceDown(0);
		}

		return val;
	}

	function balanceUp(index:Int)
	{
		var current = index;
		while (current > 0)
		{
			var parent = (current - 1) >> 1;

			if (comparator(heap[2 * current], heap[2 * parent]) < 0)
				swap(2 * current, 2 * parent);
			if (comparator(heap[2 * current + 1], heap[2 * parent + 1]) > 0)
				swap(2 * current + 1, 2 * parent + 1);

			current = parent;
		}
	}

	function balanceDown(index:Int)
	{
		var current = index;
		var size = heap.length >> 1;

		while (current < size)
		{
			final l = 2 * current + 1;
			final r = l + 1;

			var sm = current;
			var lg = current;

			if (l < size)
			{
				if (comparator(heap[2 * l], heap[2 * sm]) < 0)
					sm = l;
				if (comparator(heap[2 * l + 1], heap[2 * lg + 1]) > 0)
					lg = l;
			}

			if (r < size)
			{
				if (comparator(heap[2 * r], heap[2 * sm]) < 0)
					sm = r;
				if (comparator(heap[2 * r + 1], heap[2 * lg + 1]) > 0)
					lg = r;
			}

			if (sm != current)
				swap(2 * current, 2 * sm);
			if (lg != current)
				swap(2 * current + 1, 2 * lg + 1);
			if (sm == current && lg == current)
				break;

			current = sm;
		}
	}

	function swap(i:Int, j:Int)
	{
		var temp = heap[i];
		heap[i] = heap[j];
		heap[j] = temp;
	}
}
