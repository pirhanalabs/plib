package plib.common.messages;

abstract MessageID(String)
{
	public inline function new(val:String)
	{
		this = val;
	}
}
