package plib.common.extensions;

class IterableExtension
{
	/**
		Returns true if exactly `count` elements match requirement `fn`.
	**/
	public static inline function exact<T>(i:Iterable<T>, count:Int, fn:T->Bool):Bool
	{
		for (e in i)
		{
			count = count - (fn(e) ? 1 : 0);
			if (count < 0)
			{
				break;
			}
		}
		return count == 0;
	}

	/**
		Returns true if at least `count` elements match the requirement `fn`.
	**/
	public static inline function some<T>(i:Iterable<T>, count:Int, fn:T->Bool):Bool
	{
		var success = false;
		for (e in i)
		{
			count = count - (fn(e) ? 1 : 0);
			if (count == 0)
			{
				success = true;
				break;
			}
		}
		return success;
	}

	/**
		Returns true if any element match the requirement `fn`.
	**/
	public static inline function any<T>(i:Iterable<T>, fn:T->Bool):Bool
	{
		var success = false;
		for (e in i)
		{
			if (fn(e))
			{
				success = true;
				break;
			}
		}
		return success;
	}

	/**
		Returns the element that match the smallest `fn` value.
	**/
	public static inline function getMinElement<T>(i:Iterable<T>, fn:T->Int):Null<T>
	{
		var it = i.iterator();
		var val = 0;
		var min = 0;
		var el:Null<T> = null;
		var e:Null<T> = null;

		while (it.hasNext())
		{
			e = it.next();
			val = fn(e);
			if (el == null || val < min)
			{
				min = val;
				el = e;
			}
		}

		return el;
	}

	/**
		Returns the element that match the biggest 'fn' result.
	**/
	public static inline function getMaxElement<T>(i:Iterable<T>, fn:T->Int):Null<T>
	{
		var it = i.iterator();
		var val = 0;
		var max = 0;
		var el:Null<T> = null;
		var e:Null<T> = null;

		while (it.hasNext())
		{
			e = it.next();
			val = fn(e);
			if (el == null || val > max)
			{
				max = val;
				el = e;
			}
		}

		return el;
	}

	/**
		Returns the max value of `fn`.
	**/
	public static inline function getMaxValue<T>(i:Iterable<T>, fn:T->Int):Int
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

	/**
		Returns the min value of `fn`.
	**/
	public static inline function getMinValue<T>(i:Iterable<T>, fn:T->Int):Int
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

	/**
		returns true if all elements meet `fn` requirement.
	**/
	public static inline function every<T>(i:Iterable<T>, fn:T->Bool)
	{
		var success = true;
		for (el in i)
		{
			if (!fn(el))
			{
				success = false;
				break;
			}
		}
		return success;
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
