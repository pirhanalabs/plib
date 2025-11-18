package plib.common.extensions;

class FloatExtension
{
	public static inline function clampMin(me:Float, min:Float):Float
	{
		return me < min ? min : me;
	}

	public static inline function clampMax(me:Float, max:Float):Float
	{
		return me > max ? max : me;
	}

	public static inline function int(me:Float):Int
	{
		return Math.floor(me);
	}

	public static inline function pretty(me:Float, precision:Int = 2):Float
	{
		if (precision == 0)
			return Math.round(me);
		final d = Math.pow(10, precision);
		return Math.round(me * d) / d;
	}

	public static inline function clamp(me:Float, min:Float, max:Float):Float
	{
		return me < min ? min : me > max ? max : me;
	}

	/**
		Returns if the number is between min and max, inclusive.
	**/
	public static inline function isBetween(me:Float, min:Float, max:Float):Bool
	{
		return me >= min && me <= max;
	}
}
