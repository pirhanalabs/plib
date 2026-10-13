package plib;

class M
{
	public static inline var PIHALF = 1.5707963267948966;
	public static inline var PI = 3.141592653589793;
	public static inline var PI2 = 6.283185307179586;
	public static inline var ANGLE_360 = PI2;
	public static inline var ANGLE_180 = PI;
	public static inline var ANGLE_90 = PIHALF;
	public static inline var ANGLE_45 = 0.785398163397448;
	public static inline var SQRT2 = 1.414213562373095;

	public static inline var RAD_TO_DEG = 180 / PI;
	public static inline var DEG_TO_RAD = PI / 180;

	public static inline var UINT8_MAX = 0xFF;
	public static inline var INT8_MAX = 0x7F;
	public static inline var INT8_MIN = -0x80;
	public static inline var UNIT16_MAX = 0xFFFF;
	public static inline var INT16_MAX = 0x7FFF;
	public static inline var INT16_MIN = -0x8000;
	public static inline var UINT32_MAX = 0xFFFFFFFF;
	public static inline var INT32_MAX = 0x7FFFFFFF;
	public static inline var INT32_MIN = -0x80000000;
	public static inline var FLOAT_MAX = 3.4028234663852886e+38;
	public static inline var FLOAT_MIN = -3.4028234663852886e+38;
	public static inline var DOUBLE_MAX = 1.7976931348623157e+308;
	public static inline var DOUBLE_MIN = -1.7976931348623157e+308;

	public static inline var EPS = 1e-6;

	/**
		Returns the maximum integer value that is not greater than v.
	**/
	public static inline function floor(v:Float):Int
	{
		return Math.floor(v);
	}

	/**
		Returns the smallest integer value that is not less than v.
	**/
	public static inline function ceil(v:Float):Int
	{
		return Math.ceil(v);
	}

	/**
		Rounds v to the nearest integer value.
	**/
	public static inline function round(v:Float):Int
	{
		// return abs(v % 1) < 0.5 ? floor(v) : ceil(v);
		return Std.int(v > 0 ? v + 0.5 : v < 0 ? v - 0.5 : 0);
	}

	/** 
		Clamps a value between min and max. 
	**/
	public static inline function clamp<T:Float>(val:T, min:T, max:T):T
	{
		return val < min ? min : val > max ? max : val;
	}

	/** 
		Returns the smallest value between a and b. 
	**/
	public static inline function min<T:Float>(a:T, b:T):T
	{
		return a < b ? a : b;
	}

	/** 
		Returns the biggest value between a and b. 
	**/
	public static inline function max<T:Float>(a:T, b:T):T
	{
		return a < b ? b : a;
	}

	/** 
		Returns the absolute value of a number. 
	**/
	public static inline function abs<T:Float>(v:T):T
	{
		return v < 0 ? -v : v;
	}

	/** 
		Returns the square value of a number. 
	**/
	public static inline function square<T:Float>(v:T):T
	{
		return v * v;
	}

	/** 
		Returns the cube value of a number. 
	**/
	public static inline function cube<T:Float>(v:T):T
	{
		return square(square(v));
	}

	/** 
		Pow for floating point exponents. 
	**/
	public static inline function pow(v:Float, e:Float):Float
	{
		return Math.pow(v, e);
	}

	/** 
		Efficient pow for integer exponents. 
	**/
	public static function ipow(v:Float, e:Int):Float
	{
		if (e == 0)
		{
			return 1.0;
		}

		if (e < 0)
		{
			v = 1 / v;
			e = -e;
		}

		if (e <= 4)
		{
			switch (e)
			{
				case 1:
					return v;
				case 2:
					return v * v;
				case 3:
					return v * v * v;
				case 4:
					return cube(v);
				default:
			}
		}

		var result = 1.0;
		var product = v;

		while (e > 0)
		{
			// if lowest bit is 1 (odd number) using bitwise AND
			if ((e & 1) == 1)
			{
				result *= product;
			}
			product *= product;
			e = e >> 1;
		}
		return result;
	}

	/** 
		Returns the distance between two points. 
	**/
	public static inline function dist(x1:Float, y1:Float, x2:Float, y2:Float):Float
	{
		var dx = x2 - x1;
		var dy = y2 - y1;
		return Math.sqrt((dx * dx) + (dy * dy));
	}

	/** 
		Returns the squared distance between two points. 
	**/
	public static inline function distsq(x1:Float, y1:Float, x2:Float, y2:Float):Float
	{
		var dx = x2 - x1;
		var dy = y2 - y1;
		return (dx * dx) + (dy * dy);
	}

	/** 
		Returns true if [x2, y2] is within distance of [x1, y1]. 
	**/
	public static inline function inrange(x1:Float, y1:Float, x2:Float, y2:Float, distance:Float):Bool
	{
		return distsq(x1, y1, x2, y2) < (distance * distance);
	}

	/** 
		Returns true if v is between min and max. 
	**/
	public static inline function between(v:Float, min:Float, max:Float):Bool
	{
		return v >= min && v <= max;
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
		return a * b >= 0.0;
	}

	/** 
		Rounds a float to the given precision. 
	**/
	public static inline function pretty(x:Float, precision:Int = 0):Float
	{
		if (precision == 0)
			return round(x);
		var d = ipow(10, precision);
		return round(x * d) / d;
	}

	/** 
		Returns true if v is even. 
	**/
	public static inline function even(v:Int)
	{
		return (v & 1) == 0;
	}

	/** 
		Returns the decimals of a given float, always positive. 
	**/
	public static inline function positiveDecimals(v:Float):Float
	{
		return abs(v - Std.int(v));
	}

	/** 
		Returns the square root of v. 
	**/
	public static inline function sqrt(v:Float):Float
	{
		return Math.sqrt(v);
	}

	/** 
		Returns the quake-style inverse square root of v. 
	**/
	public static inline function invsqrt(v:Float):Float
	{
		return 1 / sqrt(v);
	}

	/** 
		Compare two numbers using epsilon. 
	**/
	public static inline function compare(a:Float, b:Float, eps:Float):Bool
	{
		return compareZero(a - b, eps);
	}

	/** 
		Compare a number against zero using an epsilon. 
	**/
	public static inline function compareZero(v:Float, eps:Float):Bool
	{
		return v > 0 ? v < eps : -v < eps;
	}

	/** 
		Converts the boolean expression to an integer.
	**/
	public static inline function bool(v:Bool):Int
	{
		return v ? 1 : 0;
	}

	/** 
		Sets a bit. 
	**/
	public static inline function setBit(v:Int, bit:Int)
	{
		return v | (1 << bit);
	}

	/** 
		Unsets a bit. 
	**/
	public static inline function unsetBit(v:Int, bit:Int)
	{
		return v & ~(1 << bit);
	}

	/** 
		Returns true if the integer has the given bit. 
	**/
	public static inline function hasBit(v:Int, bit:Int)
	{
		return v & (1 << bit) != 0;
	}

	/**
		Returns a bitmask from bools.
	**/
	public static function bitsFromBools(a = false, b = false, c = false, d = false, e = false, f = false, g = false, h = false)
	{
		var v = 0;
		if (a)
			v = setBit(v, 0);
		if (b)
			v = setBit(v, 1);
		if (c)
			v = setBit(v, 2);
		if (d)
			v = setBit(v, 3);
		if (e)
			v = setBit(v, 4);
		if (f)
			v = setBit(v, 5);
		if (g)
			v = setBit(v, 6);
		if (h)
			v = setBit(v, 7);
		return v;
	}

	/**
		Shuffles an array.
	**/
	public static inline function shuffle<T>(a:Array<T>)
	{
		hxd.Math.shuffle(a);
	}

	public static inline function sin(v:Float)
	{
		return Math.sin(v);
	}

	/** 
		Sin, but from [0-1] 
	**/
	public static inline function sinNorm(a:Float)
	{
		return (1 + sin(a)) * 0.5;
	}

	public static inline function cos(v:Float)
	{
		return Math.cos(v);
	}

	/** 
		Cos, but from [0-1] 
	**/
	public static inline function cosNorm(a:Float)
	{
		return (1 + cos(a)) * 0.5;
	}

	public static inline function atan(v:Float)
	{
		return Math.atan(v);
	}

	public static inline function atan2(y:Float, x:Float)
	{
		return Math.atan2(y, x);
	}

	public static inline function asin(v:Float)
	{
		return Math.asin(v);
	}

	public static inline function acos(v:Float)
	{
		return Math.acos(v);
	}

	public static inline function rotateX(x:Float, y:Float, cx:Float, cy:Float, a:Float)
	{
		return cx + (x - cx) * cos(a) + (y - cy) * sin(a);
	}

	public static inline function rotateY(x:Float, y:Float, cx:Float, cy:Float, a:Float)
	{
		return cy - (x - cx) * sin(a) + (y - cy) * cos(a);
	}

	public static inline function toRadian(deg:Float)
	{
		return deg * DEG_TO_RAD;
	}

	public static inline function toDegrees(rad:Float)
	{
		return rad * RAD_TO_DEG;
	}

	/**
		Wraps a float value between [min, max)
	**/
	public static inline function wrap(v:Float, min:Float, max:Float):Float
	{
		final r = max - min;
		return r <= 0 ? min : min + mod(v - min, r);
	}

	/**
		Convenience wrap for angles.
	**/
	public static inline function wrapRad(v:Float):Float
	{
		return mod(v, PI2);
	}

	/**
		Wraps an integer value between [min, max)
	**/
	public static inline function iwrap(v:Int, min:Int, max:Int):Int
	{
		final r = max - min;

		if (r == 0)
			return min;

		var result = (v - min) % r;

		if (result < 0)
			result += r;

		return result + min;
	}

	/**
		Modulus that wraps v to [0, m). Works for negative values as well.

		Zero or negative modulus results are unspecified.
	**/
	public static inline function mod(v:Float, m:Float):Float
	{
		return ((v % m) + m) % m;
	}

	/**
		Modulus that wraps v to [0, m). Works for negative values as well.

		Zero or negative modulus results are unspecified.
	**/
	public static inline function imod(v:Int, m:Int):Int
	{
		return ((v % m) + m) % m;
	}

	/**
		Utility to place elements on a line from the center.
	**/
	public static function layout(item_size:Float, num_items:Int, pos:Int)
	{
		return (-item_size * (num_items - 1) * 0.5) + (item_size * pos);
	}
}
