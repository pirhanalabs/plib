package plib.common.extensions;

class IntExtension
{
	public static inline function clampMax(me:Int, max:Int)
	{
		return me > max ? max : me;
	}

	public static inline function clampMin(me:Int, min:Int)
	{
		return me < min ? min : me;
	}

	public static inline function clamp(me:Int, min:Int, max:Int)
	{
		return me < min ? min : me > max ? max : me;
	}

	public static inline function wrap(me:Int, min:Int, max:Int)
	{
		var range = max - min + 1;
		if (me < min)
			return me + Std.int(range * ((min - me) / range + 1)) - 1;
		return min + (me - min) % range;
	}

	/**
		Returns if the number is between min and max, inclusive.
	**/
	public static inline function isBetween(me:Int, min:Int, max:Int):Bool
	{
		return me >= min && me <= max;
	}
}
