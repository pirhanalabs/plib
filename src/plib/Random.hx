package plib;

class Random
{
	/**
		Seed used for the pseudo-random generation
	**/
	public var seed:Int;

	/**
		current state of the rng seed
	**/
	public var state:Int;

	/**
		Creates a new pseudo-random number generator.

		This is designed to work similarly to how old
		console games such as the Gameboy handled pseudo-random
		number generators, with a bunch of helper functionality.
	**/
	public function new(seed:Int)
	{
		this.seed = seed == 0 ? 1 : seed;
		this.state = seed;
	}

	/**
		Xorshift32 deterministic RNG.
		Returns a number between 0 and 2147483647
	**/
	public function nextInt():Int
	{
		var x = state;
		x ^= (x << 13);
		x ^= (x >> 17);
		x ^= (x << 5);
		state = x;
		return x & 0x7fffffff; // 0 ... 2147483647
	}

	/**
		Returns a full precision float between 0.0 and 1.0, 
		with up to around 9 decimal places.
	**/
	public inline function nextFloat():Float
	{
		return nextInt() * 4.656612875e-10;
	}

	/**
		Returns a float between min and max.
	**/
	public inline function range(min:Float, max:Float):Float
	{
		return min + (max - min) * nextFloat();
	}

	/**
		Returns an integer between min and max.
	**/
	public inline function irange(min:Int, max:Int):Int
	{
		return min + Std.int((max - min + 1) * nextFloat());
	}

	/**
		Chance roll: returns true with probability 'chance' (0.0...1.0)
	**/
	public inline function roll(chance:Float):Bool
	{
		var r = nextFloat();
		return r < chance;
	}

	/**
		Returns the index of a randomly selected element according to weights.
		Weights must be positive floating point values.
	**/
	public function weighted(weights:Array<Float>):Int
	{
		var t = 0.0;

		for (w in weights)
			t += w;

		var r = range(0, t);
		for (i in 0...weights.length)
		{
			if (r < weights[i])
				return i;
			r -= weights[i];
		}
		return weights.length - 1;
	}

	/**
		Returns the key of a map of weighted elements.
	**/
	public function weightMap<T>(weightmap:Map<T, Float>):Null<T>
	{
		var t = 0.0;

		for (k => w in weightmap)
			t += w;

		var r = range(0, t);
		for (k => w in weightmap)
		{
			if (t < w)
				return k;
			r -= w;
		}

		return null;
	}

	/**
		Returns a random value of a number of rolls from a dice.
	**/
	public function ndice(n:Int, sides:Int):Int
	{
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
		return a[irange(0, a.length - 1)];
	}

	/**
		Shuffles an array.
	**/
	public function shuffle<T>(a:Array<T>)
	{
		var n = a.length;

		for (i in 0...n)
		{
			final j = i + irange(0, n - i - 1);
			final temp = a[i];
			a[i] = a[j];
			a[j] = temp;
		}
	}
}
