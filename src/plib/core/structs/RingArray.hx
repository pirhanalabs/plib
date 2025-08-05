package core.structs;

@:generic
class RingArray<T>
{
	var h:Int;
	var t:Int;
	var c:Int;
	var a:haxe.ds.Vector<T>;

	public function new(len:Int)
	{
		if (len < 4)
		{
			len = 4;
		}
		else if (len & len - 1 > 0)
		{
			len--;
			len |= len >> 1;
			len |= len >> 2;
			len |= len >> 4;
			len |= len >> 8;
			len |= len >> 16;
			len++;
		}
		c = len - 1;
		a = new haxe.ds.Vector<T>(len);
		reset();
	}

	public function reset()
	{
		h = 0;
		t = 0;
	}

	public function push(v:T)
	{
		if (space() == 0)
			t = (t + 1) & c;
		a[h] = v;
		h = (h + 1) & c;
	}

	public function shift():Null<T>
	{
		var ret:Null<T> = null;
		if (count() > 0)
		{
			ret = a[t];
			t = (t + 1) & c;
		}
		return ret;
	}

	public function pop():Null<T>
	{
		var ret:Null<T> = null;
		if (count() > 0)
		{
			h = (h - 1) & c;
			ret = a[h];
		}
		return ret;
	}

	public function unshift(v:T)
	{
		if (space() == 0)
		{
			h = (h - 1) & c;
		}
		t = (t - 1) & c;
		a[t] = v;
	}

	public function toString()
	{
		return '[head: $h, tail: $t, capacity:$c]';
	}

	public inline function count()
	{
		return (h - t) & c;
	}

	public function space()
	{
		return (t - h - 1) & c;
	}
}