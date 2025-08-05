package plib.core.extensions;

class IterableExtension
{
	public static inline function getMax<T>(i:Iterable<T>, fn:T->Int):Int
	{
		var it = i.iterator();
		var val = 0;
		var max = 0;

		if (it.hasNext())
		{
			max = fn(it.next());

			while (it.hasNext())
			{
				val = fn(it.next());
				if (val > max)
				{
					max = val;
				}
			}
		}
		return max;
	}

	public static inline function getMin<T>(i:Iterable<T>, fn:T->Int):Int
	{
		var it = i.iterator();
		var val = 0;
		var min = 0;

		if (it.hasNext())
		{
			min = fn(it.next());

			while (it.hasNext())
			{
				val = fn(it.next());
				if (val < min)
				{
					min = val;
				}
			}
		}
		return min;
	}

	public static inline function has<T>(i:Iterable<T>, item:T)
	{
		return Lambda.has(i, item);
	}

	public static inline function find<T>(i:Iterable<T>, fn:T->Bool)
	{
		return Lambda.find(i, fn);
	}

	public static inline function filter<T>(i:Iterable<T>, fn:T->Bool)
	{
		return Lambda.filter(i, fn);
	}
}
