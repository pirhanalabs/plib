package plib;

class MathTools
{
	inline public static final PI_HALF = 1.5707963267948966;
	inline public static final PI = 3.141592653589793;
	inline public static final PI2 = 6.283185307179586;
	inline public static final ANGLE_360 = PI2;
	inline public static final ANGLE_180 = PI;
	inline public static final ANGLE_90 = PI_HALF;
	inline public static final ANGLE_45 = 0.785398163397448;
	inline public static final SQRT2 = 1.414213562373095;

	inline public static final RAD_TO_DEG = 180 / PI;
	inline public static final DEG_TO_RAD = PI / 180;

	inline public static final UINT8_MAX = 0xFF;
	inline public static final INT8_MAX = 0x7F;
	inline public static final INT8_MIN = -0x80;
	inline public static final UNIT16_MAX = 0xFFFF;
	inline public static final INT16_MAX = 0x7FFF;
	inline public static final INT16_MIN = -0x8000;
	inline public static final UINT32_MAX = 0xFFFFFFFF;
	inline public static final INT32_MAX = 0x7FFFFFFF;
	inline public static final INT32_MIN = -0x80000000;
	inline public static final FLOAT_MAX = 3.4028234663852886e+38;
	inline public static final FLOAT_MIN = -3.4028234663852886e+38;
	inline public static final DOUBLE_MAX = 1.7976931348623157e+308;
	inline public static final DOUBLE_MIN = -1.7976931348623157e+308;

	public static inline function NaN()
	{
		return Math.NaN;
	}

	public static inline function POSITIVE_INFINITY()
	{
		return Math.POSITIVE_INFINITY;
	}

	public static inline function NEGATIVE_INFINITY()
	{
		return Math.NEGATIVE_INFINITY;
	}

	public static inline function fabs(x:Float):Float
	{
		return x < 0 ? -x : x;
	}

	public static inline function ifabs(x:Int):Int
	{
		return x < 0 ? -x : x;
	}

	/**
		Converts degrees to radians.
	**/
	public static inline function toRadian(deg:Float)
	{
		return deg * MathTools.DEG_TO_RAD;
	}

	/**
		Converts radians to degrees.
	**/
	public static inline function toDegree(rad:Float)
	{
		return rad * MathTools.RAD_TO_DEG;
	}

	/**
		Returns the angle between two points, in radians.
	**/
	public static inline function angle(x1:Float, y1:Float, x2:Float, y2:Float)
	{
		return Math.atan2(y2 - y1, x2 - x1);
	}

	/**
		Discards a given number of decimals on a float and keeps `precision` decimals. 
	**/
	public static inline function pretty(x:Float, precision = 2):Float
	{
		if (precision == 0)
			return Math.round(x);
		var d = Math.pow(10, precision);
		return Math.round(x * d) / d;
	}

	/**
		Randomly picks a float between min and max, seeded.    
	**/
	public static function seeded_rand(min:Float, max:Float, seed:hxd.Rand)
	{
		return seed.rand() * (max - min) + min;
	}

	/**
		Randomly picks an integer between min and max, seeded.
	**/
	public static function seeded_irand(min:Int, max:Int, seed:hxd.Rand)
	{
		return Math.floor(seed.rand() * (max - min)) + min;
	}

	/**
		Picks a random item from an array, seeded.
	**/
	public static inline function seeded_pick<T>(a:Array<T>, start = -1, end:Int = -1, seed:hxd.Rand):T
	{
		start = start < 0 ? 0 : start;
		end = end < 0 ? a.length - 1 : end;
		return a[MathTools.seeded_irand(start, end, seed)];
	}

	/**
		Randomly picks a float between min and max, unseeded.    
	**/
	public static inline function rand(min:Float, max:Float)
	{
		return Math.random() * (max - min) + min;
	}

	/**
		Randomly picks an integer between min and max, unseeded.
	**/
	public static inline function irand(min:Int, max:Int):Int
	{
		return Math.floor(Math.random() * (max - min + 1)) + min;
	}

	/**
		Picks a random item from an array, unseeded.
	**/
	public static inline function pick<T>(a:Array<T>, start = -1, end:Int = -1):T
	{
		start = start < 0 ? 0 : start;
		end = end < 0 ? a.length - 1 : end;
		return a[MathTools.irand(start, end)];
	}

	/**
		Returns the distance between two points
	**/
	public static inline function distance(x1:Float, y1:Float, x2:Float, y2:Float)
	{
		return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
	}

	/**
		returns if x is between min and max
	**/
	public static inline function inRange(x:Float, min:Float, max:Float)
	{
		return x >= min && x <= max;
	}

	/**
		Returns the minimum value as an integer
	**/
	public static inline function imin(a:Int, b:Int)
	{
		return a < b ? a : b;
	}

	/**
		Returns the maximum value as an integer
	**/
	public static inline function imax(a:Int, b:Int)
	{
		return a > b ? a : b;
	}

	/**
		Returns the absolute value as an integer.
	**/
	public static inline function iabs(val:Int)
	{
		return val < 0 ? -val : val;
	}

	/**
		Returns the sign of x.
	**/
	public static inline function sign(x:Float)
	{
		return (x > 0) ? 1 : (x < 0 ? -1 : 0);
	}

	/**
		Returns a random sign.
	**/
	public static inline function randsign()
	{
		return sign(irand(-1, 1) + 0.1);
	}

	/**
		Wraps x between min and max. If it passes a value treshold, it will return on the other side
	**/
	public static inline function wrap(x:Int, min:Int, max:Int)
	{
		return x < min ? (x - min) + max + 1 : ((x > max) ? (x - max) + min - 1 : x);
	}

	/**
		Clamps x between min and max.
	**/
	public static inline function clamp(x:Float, min:Float, max:Float)
	{
		return x < min ? min : x > max ? max : x;
	}

	/**
		Clamps x between min and max.
	**/
	public static inline function iclamp(x:Int, min:Int, max:Int)
	{
		return x < min ? min : x > max ? max : x;
	}

	/**
		Lerp between two values. To do tween interpolation, see `Tween.hx`
	**/
	inline public static function lerp(a:Float, b:Float, t:Float)
	{
		return a + (b - a) * t;
	}

	/**
		Modulo supporting negative values properly
	**/
	public inline static function modneg(n:Float, mod:Float)
	{
		while (n > mod)
			n -= mod * 2;
		while (n < -mod)
			n += mod * 2;
		return n;
	}

	public static inline function range(val:Float, omin:Float, omax:Float, nmin:Float, nmax:Float)
	{
		return (((val - omin) * (nmax - nmin)) / (omax - omin)) + nmin;
	}

	/**
		Creates a bezier curve. It is applied to a single axis at a time (x or y). call this on each to get a bezier curve point
		@param t progress on the bezier curve
		@param a first point on the bezier curve
		@param b second point on the bezier curve
		@param c third point on the bezier curve
	**/
	public static inline function bezier3(t:Float, a:Float, b:Float, c:Float)
	{
		return (1 - t) * (1 - t) * a + 2 * (1 - t) * t * b + t * t * c;
	}

	/**
		allow to center multiple elements.
	**/
	public static function layout(item_size:Float, num_items:Int, pos:Int)
	{
		return (-item_size * (num_items - 1) * 0.5) + (item_size * pos);
	}

	/**
		Returns the square root of a number
	**/
	private function sqrt(num:Int):Float
	{
		var t = 0.0;
		var r = num * 0.5;
		do
		{
			t = r;
			r = (t + (num / t)) * 0.5;
		}
		while ((t - r) != 0);
		return r;
	}

	/**
		gets a subrange ratio between two values.

		[val <= min] = 0 and [val >= max] = 1
	**/
	public static function subrng(val:Float, min:Float, max:Float)
	{
		return Math.min(1, Math.max(0, val - min) / (max - min));
	}

	public static function ioscillate(val:Int, min:Int, max:Int):Int
	{
		return Std.int(oscillate(val, min, max));
	}

	public static function oscillate(val:Float, min:Float, max:Float)
	{
		var range = max - min;
		var t = (val - min) % (range * 2);

		if (t < 0)
		{
			t += range * 2;
		}

		return min + range - Math.abs(range - t);
	}
}
