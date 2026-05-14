package plib.common.utils;

abstract AbstractEventDispatcher<T>(Array<T->Void>)
{
	public inline function new()
	{
		this = [];
	}

	public inline function add(listener:T->Void)
	{
		this.push(listener);
		return abstract;
	}

	public inline function remove(listener:T->Void)
	{
		this.remove(listener);
		return abstract;
	}

	public inline function clear()
	{
		while (this.length > 0)
		{
			this.pop();
		}
	}

	public inline function dispatch(data:T)
	{
		for (fn in this)
		{
			if (fn != null)
				fn(data);
		}
	}
}
