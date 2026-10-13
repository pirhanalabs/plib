package plib.utils;

/** 
	Lightweight argument/invariant checks. 
**/
class Assert
{
	/** 
		Returns `val` or throws `msg` when it is null. 
	**/
	public static inline function notNull<T>(val:T, msg:String = ''):T
	{
		if (val == null)
		{
			throw msg;
		}
		return val;
	}
}
