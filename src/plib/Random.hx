package plib;

/**
	Seeded xorshift32 generator with helpers for game randomness.
**/
class Random
{
	/**
		Seed used for the pseudo-random generation.
	**/
	public var seed(default, null):Int;

	/**
		current generator state.
	**/
	public var state(default, null):Int;

	/**
		Creates a new pseudo-random number generator.

		This is designed to work similarly to how old
		console games such as the Gameboy handled pseudo-random
		number generators, with helper functionality.
	**/
	public function new(seed:Int)
	{
		reseed(seed);
	}

	/**
		Changes the seed and starts its sequence from the beginning.
	**/
	public function reseed(seed:Int)
	{
		this.seed = seed == 0 ? 1 : seed;
		this.state = this.seed;
	}

	/**
		Restart the sequence using the current seed.
	**/
	public inline function reset()
	{
		state = seed;
	}

	/**
		Advances the full 32-bit state, returned as a signed Int.
	**/
	private inline function nextBits():Int
	{
		var x = state;
		x ^= x << 13;
		x ^= x >>> 17;
		x ^= x << 5;
		state = x;
		return x;
	}

	/**
		Returns a non-negative integer between [0, 2147483647].
	**/
	public inline function nextInt():Int
	{
		return nextBits() & 0x7FFFFFFF;
	}

	/**
		Returns a number between [0,1), 1 being excluded.
	**/
	public inline function nextFloat():Float
	{
		return nextInt() / 2147483648.0;
	}

	/**
		Range between min and max.
	**/
	public function range(min:Float, max:Float):Float
	{
		var t = nextFloat();
		if (min == max)
		{
			return min;
		}

		if (min > max)
		{
			var tmp = min;
			min = max;
			max = tmp;
		}

		return min < 0 && max > 0 ? min * (1 - t) + max * t : min + (max - min) * t;
	}

	/**
		Range between min and max, max included.
	**/
	public function irange(min:Int, max:Int)
	{
		if (min > max)
		{
			var tmp = min;
			min = max;
			max = tmp;
		}

		if (min == max)
		{
			return min;
		}

		var span = (max : Float) - min + 1.0;
		var capacity = span <= 2147483648.0 ? 2147483648.0 : 4294967296.0;
		var limit = Math.ffloor(capacity / span) * span;
		var sample:Float;

		do
		{
			if (capacity == 2147483648.0)
			{
				sample = nextInt();
			}
			else
			{
				var high = nextInt() & 0xFFFF;
				var low = nextInt() & 0xFFFF;
				sample = high * 65536.0 + low;
			}
		}
		while (sample >= limit);

		return Std.int((min : Float) + sample % span);
	}

	/**
		Chance roll between [0-1). If chance is higher than the roll, returns true.
	**/
	public function roll(chance:Float):Bool
	{
		return nextFloat() < chance;
	}

	/**
		Chance roll between [0, max]. If chance is higher than the roll, returns true.
	**/
	public function iroll(chance:Int, max = 255):Bool
	{
		return irange(0, max) < chance;
	}

	/**
		Returns a random sign.
	**/
	public inline function sign()
	{
		return irange(0, 1) == 0 ? -1 : 1;
	}

	/**
		Gets a random weighted list element. Ignores 0 or lower weights.
		Will return -1 if no fitting candidate is found.
	**/
	public function weightedIndex<T:WeightedElement>(list:Array<T>):Int
	{
		if (list == null || list.length == 0)
		{
			return -1;
		}

		var total = 0.0;
		var lastPositive = -1;

		for (i in 0...list.length)
		{
			if (list[i] == null)
				continue;

			var weight = list[i].weight;
			if (!Math.isFinite(weight) || weight <= 0)
				continue;
			total += weight;
			lastPositive = i;
		}

		if (total == 0 || !Math.isFinite(total))
		{
			return -1;
		}

		var r = nextFloat() * total;
		for (i in 0...list.length)
		{
			if (list[i] == null)
				continue;

			var w = list[i].weight;
			if (!Math.isFinite(w) || w <= 0)
			{
				continue;
			}
			if (r < w)
			{
				return i;
			}
			r -= w;
		}

		return lastPositive;
	}

	public function weightedItem<T:WeightedElement>(list:Array<T>):T
	{
		var index = weightedIndex(list);
		return index > -1 ? list[index] : null;
	}

	/**
		Returns a random value of a number of rolls from a dice.
		If the maximum (n * sides) exceeds 2147483647, results
		are unspecified.
	**/
	public function ndice(n:Int, sides:Int):Int
	{
		if (n < 0)
		{
			return 0;
		}

		if (sides < 1)
		{
			sides = 1;
		}

		var total = 0;
		for (i in 0...n)
		{
			total += irange(1, sides);
		}
		return total;
	}

	/**
		Picks a value from an array.
	**/
	public function pick<T>(a:Array<T>):T
	{
		if (a == null || a.length == 0)
		{
			return null;
		}

		return a[irange(0, a.length - 1)];
	}

	/**
		Returns a number of random elements from an array. Elements will be from
		different indexes of the array if possible, unless count is higher 
		than the array size.
	**/
	public function sample<T>(a:Array<T>, count:Int):Array<T>
	{
		if (a == null || a.length == 0 || count < 1)
		{
			return [];
		}

		var shouldShuffle = false;
		var result = [];
		var pool = a.copy();

		while (count > a.length)
		{
			count -= a.length;
			shouldShuffle = true;

			for (item in a)
			{
				result.push(item);
			}
		}

		for (i in 0...count)
		{
			var j = irange(i, pool.length - 1);
			var item = pool[j];
			pool[j] = pool[i];
			pool[i] = item;
			result.push(item);
		}

		return shouldShuffle ? shuffle(result) : result;
	}

	/**
		Shuffles an array in place and returns the same array.
	**/
	public function shuffle<T>(a:Array<T>):Array<T>
	{
		if (a == null)
		{
			return null;
		}

		var i = a.length - 1;

		while (i > 0)
		{
			var j = irange(0, i);
			var item = a[i];
			a[i] = a[j];
			a[j] = item;
			i--;
		}

		return a;
	}
}

private typedef WeightedElement =
{
	weight:Float,
}
