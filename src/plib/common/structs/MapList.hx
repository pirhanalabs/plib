package plib.common.structs;

abstract MapList<T, K>(Map<T, Array<K>>) to Map<T, Array<K>>
{
	public inline function new()
	{
		this = [];
	}

	public inline function add(key:T, value:K)
	{
		if (!hasKey(key))
			createKey(key);
		return this.get(key).push(value);
	}

	public inline function get(key:T)
	{
		return this.get(key);
	}

	public inline function remove(key:T, value:K)
	{
		return hasKey(key) && this.get(key).remove(value);
	}

	public inline function has(key:T, value:K)
	{
		return hasKey(key) && this.get(key).contains(value);
	}

	public inline function hasKey(key:T)
	{
		return this.exists(key);
	}

	private inline function createKey(key:T)
	{
		this[key] = [];
	}
}
