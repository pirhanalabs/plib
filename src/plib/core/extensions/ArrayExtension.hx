package plib.core.extensions;

class ArrayExtension
{
	/**
		Fast way to filter the array without allocating a new array.
		This method is fastest, but does not keep the array order.
		Speed 0(n)
	**/
	public inline static function fastUnsortedFilter<T>(a:Array<T>, cond:T->Bool)
	{
		var i = 0;
		while (i < a.length)
		{
			if (!cond(a[i]))
			{
				a[i] = a[a.length - 1];
				a.pop();
			}
			else
			{
				i++;
			}
		}
	}

	/**
		Fast way to filter the array without allocating a new array.
		This method is fastest, and keeps the array order.
		Speed 0(n)
	**/
	public inline static function fastOrderedFilter<T>(a:Array<T>, cond:T->Bool)
	{
		var write = 0;
		for (read in 0...a.length)
		{
			if (cond(a[read]))
			{
				a[write++] = a[read];
			}
		}
		a.resize(write);
	}

	public static function each<T>(a:Array<T>, fn:T->Void)
	{
		for (val in a)
		{
			fn(val);
		}
	}

	public static function ieach<T>(a:Array<T>, fn:T->Int->Void)
	{
		for (i in 0...a.length)
		{
			var val = a[i];
			fn(val, i);
		}
	}

	public static function eachsafe<T>(a:Array<T>, fn:T->Void)
	{
		for (val in a.iterator())
		{
			fn(val);
		}
	}

	public static function pick<T>(a:Array<T>, ?seed:hxd.Rand)
	{
		if (seed != null)
		{
			return MathTools.seeded_pick(a, seed);
		}
		else
		{
			return MathTools.pick(a);
		}
	}
}
