package plib;

typedef EasingFunction = Float->Float;

/** 
	Stateless easing curves for animator/tween ratios. 
**/
class Ease
{
	private static inline var BACK_C1 = 1.70158;
	private static inline var BACK_C2 = BACK_C1 * 1.525;
	private static inline var BACK_C3 = BACK_C1 + 1;

	/** 
		Quadratic acceleration. 
	**/
	public static inline function inQuad(t:Float):Float
	{
		return t * t;
	}

	/** 
		Quadratic deceleration. 
	**/
	public static inline function outQuad(t:Float):Float
	{
		return 1 - (1 - t) * (1 - t);
	}

	/** 
		Symmetric quadratic acceleration and deceleration. 
	**/
	public static inline function inOutQuad(t:Float):Float
	{
		return t < 0.5 ? 2 * t * t : 1 - M.pow(-2 * t + 2, 2) * 0.5;
	}

	/** 
		Cubic acceleration. 
	**/
	public static inline function inCubic(t:Float):Float
	{
		return t * t * t;
	}

	/** 
		Cubic deceleration. 
	**/
	public static inline function outCubic(t:Float):Float
	{
		final u = 1 - t;
		return 1 - u * u * u;
	}

	/** 
		Symmetric cubic acceleration and deceleration. 
	**/
	public static inline function inOutCubic(t:Float):Float
	{
		return t < 0.5 ? 4 * t * t * t : 1 - M.pow(-2 * t + 2, 3) * 0.5;
	}

	/** 
		Gentle sinusoidal acceleration. 
	**/
	public static inline function inSine(t:Float):Float
	{
		return 1 - M.cos(t * M.PIHALF);
	}

	/** 
		Gentle sinusoidal deceleration. 
	**/
	public static inline function outSine(t:Float):Float
	{
		return M.sin(t * M.PIHALF);
	}

	/** 
		Symmetric sinusoidal acceleration and deceleration. 
	**/
	public static inline function inOutSine(t:Float):Float
	{
		return -(M.cos(M.PI * t) - 1) * 0.5;
	}

	/** 
		Pulls backward before accelerating forward. 
	**/
	public static inline function inBack(t:Float):Float
	{
		return BACK_C3 * t * t * t - BACK_C1 * t * t;
	}

	/** 
		Overshoots the destination before settling. 
	**/
	public static inline function outBack(t:Float):Float
	{
		final u = t - 1;
		return 1 + BACK_C3 * u * u * u + BACK_C1 * u * u;
	}

	/** 
		Applies back overshoot at both ends. 
	**/
	public static function inOutBack(t:Float):Float
	{
		if (t < 0.5)
		{
			final x = 2 * t;
			return x * x * ((BACK_C2 + 1) * x - BACK_C2) * 0.5;
		}
		final x = 2 * t - 2;
		return (x * x * ((BACK_C2 + 1) * x + BACK_C2) + 2) * 0.5;
	}

	/** 
		Builds a back-in curve with controlled overshoot. 
	**/
	public static function customBackIn(overshoot:Float):EasingFunction
	{
		return t ->
		{
			final c = overshoot + 1;
			return c * t * t * t - overshoot * t * t;
		};
	}

	/** 
		Builds a back-out curve with controlled overshoot. 
	**/
	public static function customBackOut(overshoot:Float):EasingFunction
	{
		return t ->
		{
			final u = t - 1;
			final c = overshoot + 1;
			return 1 + c * u * u * u + overshoot * u * u;
		};
	}

	/** 
		Builds a symmetric back curve with controlled overshoot. 
	**/
	public static function customBackInOut(overshoot:Float):EasingFunction
	{
		final c = overshoot * 1.525;
		return t ->
		{
			if (t < 0.5)
			{
				final x = 2 * t;
				return x * x * ((c + 1) * x - c) * 0.5;
			}
			final x = 2 * t - 2;
			return (x * x * ((c + 1) * x + c) + 2) * 0.5;
		};
	}

	/** 
		Decelerates through progressively smaller bounces. 
	**/
	public static function outBounce(t:Float):Float
	{
		final n = 7.5625;
		final d = 2.75;

		if (t < 1 / d)
			return n * t * t;

		if (t < 2 / d)
		{
			final x = t - 1.5 / d;
			return n * x * x + 0.75;
		}

		if (t < 2.5 / d)
		{
			final x = t - 2.25 / d;
			return n * x * x + 0.9375;
		}

		final x = t - 2.625 / d;
		return n * x * x + 0.984375;
	}

	/** 
		Accelerates using a reversed bounce curve. 
	**/
	public static inline function inBounce(t:Float):Float
	{
		return 1 - outBounce(1 - t);
	}

	/** 
		Applies bounce motion at both ends. 
	**/
	public static inline function inOutBounce(t:Float):Float
	{
		return t < 0.5 ? (1 - outBounce(1 - 2 * t)) * 0.5 : (1 + outBounce(2 * t - 1)) * 0.5;
	}

	/** 
		Accelerates with an elastic oscillation. 
	**/
	public static function inElastic(t:Float):Float
	{
		if (t == 0 || t == 1)
			return t;

		final c = M.PI2 / 3;
		return -M.pow(2, 10 * t - 10) * M.sin((t * 10 - 10.75) * c);
	}

	/** 
		Settles with an elastic oscillation. 
	**/
	public static function outElastic(t:Float):Float
	{
		if (t == 0 || t == 1)
			return t;

		final c = M.PI2 / 3;
		return M.pow(2, -10 * t) * M.sin((t * 10 - 0.75) * c) + 1;
	}

	/** 
		Applies elastic oscillation at both ends. 
	**/
	public static function inOutElastic(t:Float):Float
	{
		if (t == 0 || t == 1)
			return t;

		final c = M.PI2 / 4.5;
		final z = 20 * t - 11.125;
		final s = M.sin(z * c);
		return t < 0.5 ? -(M.pow(2, 20 * t - 10) * s) * 0.5 : M.pow(2, -20 * t + 10) * s * 0.5 + 1;
	}

	/** 
		Builds an elastic-out curve with amplitude and period. 
	**/
	public static function customElasticOut(amplitude:Float, period:Float):EasingFunction
	{
		if (period <= 0)
			throw 'Elastic period must be greater than zero.';

		final safeAmplitude = Math.max(1, amplitude);
		final phase = M.asin(1 / safeAmplitude) * period / M.PI2;

		return t ->
		{
			if (t == 0 || t == 1)
				return t;

			return safeAmplitude * M.pow(2, -10 * t) * M.sin((t - phase) * M.PI2 / period) + 1;
		};
	}

	/** 
		Cubic smoothstep. 
	**/
	public static inline function smoothstep(t:Float):Float
	{
		t = M.clamp(t, 0, 1);
		return t * t * (3 - 2 * t);
	}

	/** 
		Quintic smoothstep. 
	**/
	public static inline function smootherstep(t:Float):Float
	{
		t = M.clamp(t, 0, 1);
		return t * t * t * (t * (t * 6 - 15) + 10);
	}

	/** 
		Jumps to one immediately after the starting boundary. 
	**/
	public static inline function stepstart(t:Float)
	{
		return t <= 0 ? 0 : 1;
	}

	/** 
		Remains zero until the ending boundary. 
	**/
	public static inline function stepend(t:Float)
	{
		return t < 1 ? 0 : 1;
	}

	/** 
		Builds a curve quantized into `count` discrete steps. 
	**/
	public static inline function steps(count:Int):EasingFunction
	{
		if (count <= 0)
			throw 'Step count must be greater than zero.';

		return t ->
		{
			t = M.clamp(t, 0, 1);
			return M.floor(t * count) / count;
		};
	}

	// CSS-Style cubic bezier easing

	/** 
		Builds a CSS-style unit cubic Bézier easing from two control points. 
	**/
	public static function cubicBezier(x1:Float, y1:Float, x2:Float, y2:Float):EasingFunction
	{
		if (x1 < 0 || x1 > 1 || x2 < 0 || x2 > 1)
			throw 'Cubic Bezier x coordinates must be between 0 and 1';

		return x ->
		{
			if (x <= 0)
				return 0;

			if (x >= 1)
				return 1;

			var lower = 0.0;
			var upper = 1.0;
			var t = x;

			for (_ in 0...16)
			{
				t = (lower + upper) * 0.5;
				final estimate = bezierCoordinate(0, x1, x2, 1, t);

				if (estimate < x)
				{
					lower = t;
				}
				else
				{
					upper = t;
				}
			}

			return bezierCoordinate(0, y1, y2, 1, t);
		}
	}

	private static inline function bezierCoordinate(start:Float, controlA:Float, controlB:Float, end:Float, t:Float):Float
	{
		final u = 1 - t;
		return u * u * u * start + 3 * u * u * t * controlA + 3 * u * t * t * controlB + t * t * t * end;
	}

	/** 
		Produces a sine arch that is zero at both boundaries and one halfway. 
	**/
	public static inline function sinbound(t:Float):Float
	{
		return t % M.PI2;
	}

	/** 
		Reverses an easing curve in time and value. 
	**/
	public static function reverse(ease:EasingFunction):EasingFunction
	{
		return t -> 1 - ease(1 - t);
	}

	/** 
		Converts a one-sided curve into a symmetric in-out curve. 
	**/
	public static function inOut(ease:EasingFunction):EasingFunction
	{
		return t ->
		{
			return t < 0.5 ? ease(t * 2) * 0.5 : 1 - ease((1 - t) * 2) * 0.5;
		};
	}

	/** 
		Returns `outer(inner(t))` for reusable curve composition. 
	**/
	public static function compose(outer:EasingFunction, inner:EasingFunction):EasingFunction
	{
		return t -> outer(inner(t));
	}
}
