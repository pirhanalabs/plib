package plib.common.structs;

class Stat<T:Float>
{
	public var onChange:Null<Void->Void>;

	public var max(default, set):T;
	public var min(default, set):T;
	public var cur(default, set):T;

	public var ratioMax(get, never):Float;
	public var ratioMin(get, never):Float;
	public var ratioMaxPretty(get, never):Float;
	public var ratioMinPretty(get, never):Float;

	private var zero:T = cast 0;

	public function new()
	{
		init(zero, zero, zero);
	}

	public inline function init(cur:T, min:T, max:T)
	{
		this.min = min;
		this.max = max;
		this.cur = cur;
	}

	public inline function setBounds(min:T, max:T)
	{
		this.min = min;
		this.max = max;
		this.cur = clamp(cur);
	}

	public inline function maximize()
	{
		cur = max;
	}

	public inline function minimize()
	{
		cur = min;
	}

	public inline function isZero()
	{
		return cur == zero;
	}

	public inline function isMin()
	{
		return cur == min;
	}

	public inline function isMax()
	{
		return cur == max;
	}

	public inline function isMinOrMax()
	{
		return cur == max || cur == min;
	}

	private function clamp(v:T)
	{
		return v < min ? min : v > max ? max : v;
	}

	private inline function set_max(val:T):T
	{
		max = val;
		if (min > max)
		{
			min = max;
		}
		cur = clamp(cur);
		return max;
	}

	private inline function set_min(val:T):T
	{
		min = val;
		if (max < min)
		{
			max = min;
		}
		cur = clamp(cur);
		return min;
	}

	private inline function set_cur(val:T):T
	{
		if (onChange == null)
		{
			cur = clamp(val);
		}
		else
		{
			var old = cur;
			cur = clamp(val);
			if (old != cur)
			{
				onChange();
			}
		}
		return cur;
	}

	private inline function get_ratioMax():Float
	{
		return min == max ? 0 : (cur - min) / (max - min);
	}

	private inline function get_ratioMin():Float
	{
		return 1 - ratioMax;
	}

	private inline function get_ratioMaxPretty():Float
	{
		return MathTools.pretty(ratioMax);
	}

	private inline function get_ratioMinPretty():Float
	{
		return MathTools.pretty(ratioMin);
	}
}
