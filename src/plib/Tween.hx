package plib;

/** Allocation-free interpolation helpers used by animations and camera motion. **/
class Tween
{
	/** Linearly interpolates without clamping `t`. **/
	public static inline function lerp(a:Float, b:Float, t:Float):Float
	{
		return a * (1 - t) + b * t;
	}

	/** Applies frame-rate-independent exponential interpolation toward `b`. **/
	public static inline function lerpdt(a:Float, b:Float, t:Float, dt:Float):Float
	{
		return lerp(a, b, M.min(t * dt, 1));
	}

	/** Linearly interpolates with `t` clamped to `[0, 1]`. **/
	public static inline function lerpClamped(a:Float, b:Float, t:Float):Float
	{
		return lerp(a, b, M.clamp(t, 0, 1));
	}

	/**
		Shortest-path angle interpolation.
	**/
	public static inline function angle(from:Float, to:Float, t:Float):Float
	{
		var delta = M.mod(to - from + M.PI, M.PI2) - M.PI;
		return from + delta * t;
	}

	/**
		Finds the clamped ratio between two values.
	**/
	public static inline function ratioClamped(a:Float, b:Float, v:Float):Float
	{
		return M.clamp(ratio(a, b, v), 0.0, 1.0);
	}

	/**
		Finds the ratio between two values.
	**/
	public static inline function ratio(a:Float, b:Float, v:Float):Float
	{
		return a == b ? 0 : (v - a) / (b - a);
	}

	/** Returns the unclamped ratio locating `v` between `a` and `b`. **/
	public static inline function inverseLerp(a:Float, b:Float, v:Float):Float
	{
		return ratio(a, b, v);
	}

	/** Returns the ratio locating `v` between `a` and `b`, clamped to `[0, 1]`. **/
	public static inline function inverseLerpClamped(a:Float, b:Float, v:Float):Float
	{
		return ratioClamped(a, b, v);
	}

	/**
		Converts one range to another.
	**/
	public static inline function remap(inMin:Float, inMax:Float, outMin:Float, outMax:Float, v:Float)
	{
		return lerp(outMin, outMax, ratio(inMin, inMax, v));
	}

	/**
		Converts one range to another, clamped.
	**/
	public static inline function remapClamped(inMin:Float, inMax:Float, outMin:Float, outMax:Float, v:Float)
	{
		return lerp(outMin, outMax, ratioClamped(inMin, inMax, v));
	}

	/** Samples a scalar quadratic Bézier curve. **/
	public static inline function quadraticBezier(start:Float, control:Float, end:Float, t:Float):Float
	{
		final a = lerp(start, control, t);
		final b = lerp(control, end, t);
		return lerp(a, b, t);
	}

	/** Samples a scalar cubic Bézier curve. **/
	public static inline function cubicBezier(start:Float, controlA:Float, controlB:Float, end:Float, t:Float):Float
	{
		final a = lerp(start, controlA, t);
		final b = lerp(controlA, controlB, t);
		final c = lerp(controlB, end, t);
		final d = lerp(a, b, t);
		final e = lerp(b, c, t);
		return lerp(d, e, t);
	}

	/**
		Used to smoothdamp rotations. To move between positions, instead use smoothdampXY.

		@param a starting angle
		@param b target angle
		@param v velocity object
		@param t smooth time
		@param d delta time
		@param s max speed
	**/
	public static inline function smoothdampAngle(a:Float, b:Float, v:{velocity:Float}, t:Float, d:Float, s:Float = M.FLOAT_MAX)
	{
		final diff = M.wrap(b - a, -M.PI, M.PI);
		b = a + diff;

		final ob = b;
		t = M.max(0.0001, t);

		final o = 2 / t;
		final x = o * d;
		final exp = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x);

		var c = a - b;
		var m = s * t;

		c = M.clamp(c, -m, m);
		b = a - c;

		final tmp = (v.velocity + o * c) * d;
		v.velocity = (v.velocity - o * tmp) * exp;

		var out = b + (c + tmp) * exp;

		if ((ob - a > 0) == (out > ob))
		{
			out = ob;
			v.velocity = 0;
		}

		return M.wrap(out, -M.PI, M.PI);
	}

	/**
		@param a starting value
		@param b target value
		@param v velocity object
		@param t smooth time
		@param d delta time
		@param s max speed
	**/
	public static inline function smoothdamp(a:Float, b:Float, v:{velocity:Float}, t:Float, d:Float, s:Float = M.FLOAT_MAX)
	{
		t = M.max(0.0001, t);

		final o = 2.0 / t;
		final x = o * d;
		final exp = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x);

		var c = a - b;
		var ob = b;

		final mc = s * t;
		c = M.clamp(c, -mc, mc);
		b = a - c;

		final tmp = (v.velocity + o * c) * d;
		v.velocity = (v.velocity - o * tmp) * exp;

		var out = b + (c + tmp) * exp;

		// prevent overshoot
		if ((ob - a > 0) == (out > ob))
		{
			out = ob;
			v.velocity = 0;
		}

		return out;
	}

	/**
		Smoothdamp for objects.

		@param cur current object position
		@param b target object position
		@param v velocity object 
		@param t smooth time
		@param d delta time
		@param s max speed
	**/
	public static inline function smoothdamp2D(cur:XY, tar:XY, v:XY, t:Float, d:Float, s:Float):XY
	{
		t = M.max(0.0001, t);

		final o = 2.0 / t;
		final x = o * d;
		final exp = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x);

		final otx = tar.x;
		final oty = tar.y;

		var cx = cur.x - tar.x;
		var cy = cur.y - tar.y;

		final maxChange = s * t;
		final changeSqr = cx * cx + cy * cy;
		final maxChangeSqr = maxChange * maxChange;

		if (changeSqr > maxChangeSqr)
		{
			final scale = maxChange / M.sqrt(changeSqr);
			cx *= scale;
			cy *= scale;
		}

		final adjTarX = cur.x - cx;
		final adjTarY = cur.y - cy;

		final tmpX = (v.x + o * cx) * d;
		final tmpY = (v.y + o * cy) * d;

		v.x = (v.x - o * tmpX) * exp;
		v.y = (v.y - o * tmpY) * exp;

		var outx = adjTarX + (cx + tmpX) * exp;
		var outy = adjTarY + (cy + tmpY) * exp;

		final tardx = otx - cur.x;
		final tardy = oty - cur.y;
		final outdx = outx - otx;
		final outdy = outy - oty;

		if (tardx * outdx + tardy * outdy > 0)
		{
			outx = otx;
			outy = oty;
			v.x = 0;
			v.y = 0;
		}

		return {
			x: outx,
			y: outy,
		}
	}
}

private typedef XY =
{
	x:Float,
	y:Float,
}
