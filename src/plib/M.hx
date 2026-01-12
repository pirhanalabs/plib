package plib;

/**
	Replacement for MathTools.hx eventually (one day, one day...)
**/
class M
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

	/**
		Returns Nan value.
	**/
	public static inline function NaN()
	{
		return Math.NaN;
	}

	/**
		Returns positive infinity value.
	**/
	public static inline function POSITIVE_INFINITY()
	{
		return Math.POSITIVE_INFINITY;
	}

	/**
		Returns negative infinity value.
	**/
	public static inline function NEGATIVE_INFINITY()
	{
		return Math.NEGATIVE_INFINITY;
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
		Linear interpolation over interval with t = 0...1.
	**/
	public static inline function lerp(a:Float, b:Float, t:Float):Float
	{
		return a * (1 - t) + b * t;
	}

	/**
		Linear interpolation over interval with deltatime with 1 = 0...1.
	**/
	public static inline function lerpDelta(a:Float, b:Float, t:Float, dt:Float):Float
	{
		return lerp(a, b, fmin(t * dt, 1.0));
	}

	/**
		Lerps an angle between `a` (inclusive) and `b` (inclusive), by normalized delta `t`.
	**/
	public static inline function lerp_a(a:Float, b:Float, t:Float):Float
	{
		final d = wrap_a(b - a, -PI, PI);
		return a + d * t;
	}

	/**
		Wraps a value between min (inclusive) and max (exclusive).
	**/
	public static inline function wrap_a(v:Float, min:Float, max:Float):Float
	{
		var r = max - min;
		return v - r * floor((v - min) / r);
	}

	/**
		Wraps a float value between `min` (inclusive) and `max` (inclusive).
		If you need exclusive, use `M.wrap_a()` instead.
	**/
	public static inline function wrap_f(v:Float, min:Float, max:Float):Float
	{
		final r = max - min;
		return if (r == 0) min; else if (r < min) max - (min - v) % r; else if (r > max) min - (v - max) % r; else v;
	}

	/**
		Wraps an integer value between `min` (inclusive) and `max` (exclusive).
	**/
	public static inline function wrap_i(v:Int, min:Int, max:Int):Int
	{
		final r = max - min;
		var x = (v - min) % r;
		if (x < 0)
			x += r;
		return x + min;
	}

	/**
			Smoothdamp for angles.
		@param a starting angle
		@param b target angle
		@param v velocity object
		@param t smooth time
		@param d delta time
		@param s max speed

	**/
	public static inline function smoothdamp_a(a:Float, b:Float, v:{v:Float}, t:Float, d:Float, s:Float = FLOAT_MAX)
	{
		final diff = wrap_a(b - a, -PI, PI);
		b = a + diff;

		final ob = b;
		t = fmax(0.0001, t);

		final o = 2 / t;
		final x = o * d;
		final exp = 1 / (1 + x + .48 * x * x + .235 * x * x * x);

		var c = a - b;
		var m = s * t;
		c = clamp(c, -m, m);
		b = a - c;

		final tmp = (v.v + o * c) * d;
		v.v = (v.v - o * tmp) * exp;

		var out = b + (c + tmp) * exp;

		if ((ob - a > 0) == (out > ob))
		{
			out = ob;
			v.v = 0;
		}

		return wrap_a(out, -PI, PI);
	}

	/**
			Standard smoothdamp.
		@param a starting angle
		@param b target angle
		@param v velocity object
		@param t smooth time
		@param d delta time
		@param s max speed

	**/
	public static inline function smoothdamp(a:Float, b:Float, v:{v:Float}, t:Float, d:Float, s:Float = FLOAT_MAX)
	{
		t = fmax(0.0001, t);

		final o = 2.0 / t;
		final x = o * d;
		final exp = 1 / (1 + x + .48 * x * x + .235 * x * x * x);

		var c = a - b;
		var ob = b;

		// clamp s
		final mc = s * t;
		c = clamp(c, -mc, mc);
		b = a - c;

		final tmp = (v.v + o * c) * d;
		v.v = (v.v - o * tmp) * exp;

		var out = b + (c + tmp) * exp;

		// prevent overshoot
		if ((ob - a > 0) == (out > ob))
		{
			out = ob;
			v.v = 0;
		}

		return out;
	}

	/**
		Clamps `v` between `min` (inclusive) and `max` (inclusive)
	**/
	@:generic
	public static inline function clamp<T:Float>(v:T, min:T, max:T):T
	{
		return v < min ? min : v > max ? max : v;
	}

	/**
		Gets the maximum value from the arguments.
	**/
	@:generic
	public static inline function max<T:Float>(...args:T):T
	{
		var v:T = args[0];
		for (arg in args)
		{
			if (v < arg)
			{
				v = arg;
			}
		}
		return v;
	}

	/**
		Gets the minimum value from the arguments.
	**/
	@:generic
	public static inline function min<T:Float>(...args:T):T
	{
		var v:T = args[0];
		for (arg in args)
		{
			if (v > arg)
			{
				v = arg;
			}
		}
		return v;
	}

	/**
		Gets the maximum value between `a` and `b`.
	**/
	@:generic
	public static inline function fmax<T:Float>(a:T, b:T):T
	{
		return a < b ? b : a;
	}

	/**
		Gets the minimum value between `a` and `b`.
	**/
	@:generic
	public static inline function fmin<T:Float>(a:T, b:T):T
	{
		return a < b ? a : b;
	}

	/**
		Returns the maximum integer value that is not greater than `v`.
	**/
	public static inline function floor(v:Float):Int
	{
		return cast ffloor(v);
	}

	/**
		Returns the maximum integer value that is not greater than `v`, as a Float.
	**/
	public static inline function ffloor(v:Float):Float
	{
		return v - (v % 1);
	}

	/**
		Returns the smallest integer value that is not less than 'v'.
	**/
	public static inline function ceil(v:Float):Int
	{
		return cast fceil(v);
	}

	/**
		Returns the smallest integer value that is not less than 'v', as a Float.
	**/
	public static inline function fceil(v:Float):Float
	{
		return v + (v % 1);
	}

	/**
		Rounds `v` to the nearest integer value.
	**/
	public static inline function round(v:Float):Int
	{
		return cast fround(v);
	}

	/**
		Rounds `v` to the nearest integer value, as a Float.
	**/
	public static inline function fround(v:Float):Float
	{
		return fabs(v % 1) < 0.5 ? ffloor(v) : fround(v);
	}

	/**
		Returns the absolute value of `v`.
	**/
	@:generic
	public static inline function fabs<T:Float>(v:T):T
	{
		return v < 0 ? -v : v;
	}

	/**
		Returns the square root of a number
	**/
	public static inline function sqrt(num:Float):Float
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
		Fast inverse square root of num.
	**/
	public static function invsqrt(num:Float):Float
	{
		return 1 / sqrt(num);
	}

	/**
		Spaces values around 0, depending on `spacing`, `quantity` of elements and the current `index`.
		Values can be offset by setting `offset`.
	**/
	public static function layout(spacing:Float, quantity:Int, index:Int, offset:Float = 0.0)
	{
		return (-spacing * (quantity - 1) * 0.5) + (spacing * index) + offset;
	}

	/**
		Returns the sign of v.
	**/
	public static inline function sign(v:Float):Int
	{
		return v < 0 ? -1 : v > 0 ? 1 : 0;
	}

	/**
		Returns true if a and b have the same sign.
	**/
	public static inline function eqsign(a:Float, b:Float):Bool
	{
		return a * b >= 0;
	}

	/**
		Returns a seeded random number for a x/y coord. Result range 0->max (inclusive).
	**/
	public static inline function randSeedCoords(seed:Int, x:Int, y:Int, max:Int)
	{
		var h = seed + x * 374761393 + y * 668265263;
		h = (h ^ (h >> 13)) * 1274126177;
		return (h ^ (h >> 16)) % max;
	}

	/**
		Snaps a value to an interval.
	**/
	public static inline function snapval(v:Float, interval:Float)
	{
		return round(v / interval) * interval;
	}

	/**
		Rounds a float to given precision.
	**/
	public static inline function pretty(x:Float, precision:Int = 0):Float
	{
		if (precision == 0)
			return round(x);
		var d = Math.pow(10, precision);
		return round(x * d) / d;
	}

	/**
		Returns the angle between two points, in radians.
	**/
	public static inline function angle(x1:Float, y1:Float, x2:Float, y2:Float)
	{
		return Math.atan2(y2 - y1, x2 - x1);
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
		Returns the distance between two points
	**/
	public static inline function distance(x1:Float, y1:Float, x2:Float, y2:Float)
	{
		return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
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
		Returns a random sign. Unseeded.
	**/
	public static inline function randsign()
	{
		return sign(irand(-1, 1) + 0.1);
	}

	/**
		Modulo supporting negative values.
	**/
	public inline static function modneg(n:Float, mod:Float)
	{
		while (n > mod)
			n -= mod * 2;
		while (n < -mod)
			n += mod * 2;
		return n;
	}

	/**
		Converts a value from a range to another range.
	**/
	public static inline function toRange(val:Float, omin:Float, omax:Float, nmin:Float, nmax:Float)
	{
		return (((val - omin) * (nmax - nmin)) / (omax - omin)) + nmin;
	}

	/**
		Gets a subrange ratio (0...1) between min and max.
		If val is out of bounds, it will either be 0 or 1.
	**/
	public static function rangeRatio(val:Float, min:Float, max:Float)
	{
		return Math.min(1, Math.max(0, val - min) / (max - min));
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
}
