package core.structs;

class Collection<Key, Value>
{
	public var keys:Array<Key>;
	public var values:Array<Value>;

	var map:Map<Key, Int>;

	public function new()
	{
		values = [];
		keys = [];
	}

	public function getValue(key:Key)
	{
		var index = keys.indexOf(key);
		if (index == -1)
			return null;
		return values[index];
	}

	public function add(key:Key, val:Value)
	{
		if (keys.indexOf(key) == -1)
		{
			this.values.push(val);
			this.keys.push(key);
		}
	}

	public function remove(key:Key)
	{
		var index = this.keys.indexOf(key);

		if (index != -1)
		{
			this.keys.remove(this.keys[index]);
			this.values.remove(this.values[index]);
		}
	}

	public function iterator()
	{
		return new CollectionIterator(this);
	}
}

private typedef KeyValPair<K, T> =
{
	key:K,
	value:T
};

private class CollectionIterator<T, K>
{
	var collection:Collection<T, K>;
	var i:Int;

	public function new(collection:Collection<T, K>)
	{
		this.collection = collection;
		this.i = 0;
	}

	public function hasNext()
	{
		return i < collection.keys.length;
	}

	public function next():KeyValPair<T, K>
	{
		var data =
			{
				key: collection.keys[i],
				value: collection.values[i],
			};
		i++;
		return data;
	}
}
