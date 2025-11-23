package plib.common.extensions;

class ArrayExtension
{
	/**
		Returns the average of all values in a array.
	**/
	public inline static function average<T:Float>(a:Array<T>):Float
	{
		return totalize(a) / a.length;
	}

	/**
		A dumber, more streamlined version of reduce, only for calculating total of values.
	**/
	public inline static function totalize<T:Float>(a:Array<T>):T
	{
		return reduce(a, (acc, n) -> acc + n, cast 0);
	}

	/**
		Equivalent of javascript reduce() method, but for numerical values only.
	**/
	public inline static function reduce<T:Float>(a:Array<T>, fn:(acc:T, val:T) -> T, acc:T):T
	{
		for (el in a)
		{
			acc = fn(acc, el);
		}
		return acc;
	}

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
		if (a != null)
		{
			for (val in a)
			{
				fn(val);
			}
		}
	}

	public static function ieach<T>(a:Array<T>, fn:T->Int->Void)
	{
		if (a != null)
		{
			for (i in 0...a.length)
			{
				var val = a[i];
				fn(val, i);
			}
		}
	}

	public static function eachsafe<T>(a:Array<T>, fn:T->Void)
	{
		if (a != null)
		{
			for (val in a.iterator())
			{
				fn(val);
			}
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

	public static inline function last<T>(a:Array<T>):T
	{
		return a[a.length - 1];
	}

	/**
		Sets all index values to `value`.
	**/
	public static inline function fill<T>(a:Array<T>, value:T)
	{
		for (i in 0...a.length)
		{
			a[i] = value;
		}
	}

	public static inline function totalize(a:Array<T>, fn:T->Float):Float
	{
		var value = 0;
		each(a, e -> value += fn(e));
		return value;
	}
}
