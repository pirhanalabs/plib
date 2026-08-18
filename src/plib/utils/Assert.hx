package plib.utils;

/** Lightweight argument/invariant checks used by plib and available to games. **/
class Assert
{
	/** Returns `val` or throws `msg` when it is null, preserving the inferred type. **/
	public static inline function notNull<T>(val:T, msg:String = ''):T
	{
		if (val == null)
		{
			throw msg;
		}
		return val;
	}
}
