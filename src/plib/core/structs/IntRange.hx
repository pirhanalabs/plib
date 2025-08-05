package core.structs;

class IntRange
{
	public var min(default, null):Int;
	public var max(default, null):Int;
	public var val(default, null):Int;

	/**
		Range between min and max.
	**/
	public function new(min:Int, max:Int, defaultVal:Int)
	{
		this.min = min;
		this.max = max;
		this.val = 0;
		set(defaultVal);
	}

	/**
		Sets the minimum value of the range.
	**/
	public function setMin(amount:Int)
	{
		this.min = amount;
		set(this.val);
	}

	/**
		Sets the maximum value of the range.
	**/
	public function setMax(amount:Int)
	{
		this.max = amount;
		set(this.val);
	}

	/**
		Add to the range's value.
	**/
	public function add(amount:Int)
	{
		set(val + amount);
	}

	/**
		Sets the value of the range.
	**/
	public function set(amount:Int)
	{
		this.val = amount.clamp(min, max);
	}

	/**
		Returns the normalized value of `val` in range [`min`-`max`].
	**/
	public function ratio():Float
	{
		return val / max;
	}

	/**
		Return a randomized value between `min` and `max`.
	**/
	public function random():Int
	{
		return Std.random(max - min) + min + 1;
	}

	/**
		Returns the array [`min`, `max`].
	**/
	public function toRange()
	{
		return [min, max];
	}

	/**
		Returns the json data of this range.
	**/
	public function toJson()
	{
		return {min: Int, max: Int, val: Int};
	}
}
