package core.structs;

class PriorityQueue<T>
{
	private var heap:Array<T>;

	private var comparator:(T, T) -> Bool;

	public function new(comparator:(T, T) -> Bool)
	{
		this.comparator = comparator;
		this.heap = [];
	}

	public function find(fn:T->Bool)
	{
		return Lambda.find(heap, fn);
	}

	public function isEmpty()
	{
		return heap.length == 0;
	}

	public function add(item:T)
	{
		heap.push(item);
		bubbleUp(heap.length - 1);
	}

	public function pop():T
	{
		if (heap.length == 0)
			return null;

		var top = heap[0];
		var last = heap.pop();
		if (heap.length > 0)
		{
			heap[0] = last;
			bubbleDown(0);
		}
		return top;
	}

	private function bubbleUp(index:Int)
	{
		var parent = Math.floor((index - 1) * 0.5);
		while (index > 0 && comparator(heap[index], heap[parent]))
		{
			swap(index, parent);
			index = parent;
			parent = Math.floor((index - 1) * 0.5);
		}
	}

	private function bubbleDown(index:Int)
	{
		var left = 2 * index + 1;
		var right = 2 * index + 2;
		var smallest = index;

		if (left < heap.length && comparator(heap[left], heap[smallest]))
		{
			smallest = left;
		}

		if (right < heap.length && comparator(heap[right], heap[smallest]))
		{
			smallest = right;
		}

		if (smallest != index)
		{
			swap(index, smallest);
			bubbleDown(smallest);
		}
	}

	private function swap(i:Int, j:Int)
	{
		var temp = heap[i];
		heap[i] = heap[j];
		heap[j] = temp;
	}
}
