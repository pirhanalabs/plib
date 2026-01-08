package plib.common.extensions;

class NumberExtension
{
	public static inline function sign<T:Float>(v:T):Int
	{
		return v > 0 ? 1 : v < 0 ? -1 : 0;
	}
}
