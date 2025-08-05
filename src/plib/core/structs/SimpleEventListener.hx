package core.structs;

abstract SimpleEventListener(Array<Void->Void>)
{
	public inline function new()
	{
		this = [];
	}

	public inline function dispatch()
	{
		for (fn in this)
		{
			fn();
		}
	}

	@:op(A + B)
	private inline function add(fn:Void->Void)
	{
		this.push(fn);
	}

	@:op(A - B)
	private inline function sub(fn:Void->Void)
	{
		this.remove(fn);
	}
}
