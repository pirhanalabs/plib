package plib;

/**
	Packed 8-bit color as `0xAARRGGBB`, with value semantics.
	RGB/HSL factories and implicit RGB integer conversion default to opaque alpha.
	Implicit integers with a nonzero alpha byte preserve that alpha. Use the packed
	ARGB constructor or a factory with explicit alpha for fully transparent colors.
	HSL uses hue in degrees and sat/light in 0–1. HSL edits are quantized
	back to RGB; grayscale colors have no stored hue and report zero.
**/
abstract Color(Int) to Int
{
	/** 
		Wraps a packed ARGB value. 
	**/
	public inline function new(argb:Int)
	{
		this = argb;
	}

	/** 
		Alpha clamped to 0–255. 
	**/
	public var ai(get, set):Int;

	/** 
		Red clamped to 0–255. 
	**/
	public var ri(get, set):Int;

	/** 
		Green clamped to 0–255.
	**/
	public var gi(get, set):Int;

	/** 
		Blue clamped to 0–255. 
	**/
	public var bi(get, set):Int;

	/** 
		Alpha normalized. 
	**/
	public var af(get, set):Float;

	/** 
		Red normalized. 
	**/
	public var rf(get, set):Float;

	/** 
		Green normalized.
	**/
	public var gf(get, set):Float;

	/** 
		Blue normalized.
	**/
	public var bf(get, set):Float;

	/** 
		Hue in degrees [0, 360). Value wraps. 
	**/
	public var hue(get, set):Float;

	/** 
		HSL saturation, normalized.
	**/
	public var sat(get, set):Float;

	/** 
		HSL lightness, normalized. 
	**/
	public var light(get, set):Float;

	/** 
		Creates a Color from an integer. Treats integers without an alpha byte as opaque RGB. 
	**/
	@:from
	public static inline function fromInt(value:Int):Color
	{
		return new Color((value & 0xFF000000) == 0 ? value | 0xFF000000 : value);
	}

	/** 
		Creates a color from integer values.
	**/
	public static inline function fromRGBi(r:Int, g:Int, b:Int, a:Int = 255):Color
	{
		return new Color((clampByte(a) << 24) | (clampByte(r) << 16) | (clampByte(g) << 8) | clampByte(b));
	}

	/** 
		Creates a color from normalized values.
	**/
	public static inline function fromRGBf(r:Float, g:Float, b:Float, a:Float = 1.0):Color
	{
		return fromRGBi(toByte(r), toByte(g), toByte(b), toByte(a));
	}

	/** 
		Creates a color from hue/sat/light/alpha. 
	**/
	public static function fromHSL(h:Float, s:Float, l:Float, a:Float = 1.0):Color
	{
		h = wrapHue(h) / 60;
		s = clampUnit(s);
		l = clampUnit(l);
		var c = (1 - Math.abs(2 * l - 1)) * s;
		var x = c * (1 - Math.abs(h % 2 - 1));
		var m = l - c / 2;
		var r = 0.0;
		var g = 0.0;
		var b = 0.0;
		if (h < 1)
		{
			r = c;
			g = x;
		}
		else if (h < 2)
		{
			r = x;
			g = c;
		}
		else if (h < 3)
		{
			g = c;
			b = x;
		}
		else if (h < 4)
		{
			g = x;
			b = c;
		}
		else if (h < 5)
		{
			r = x;
			b = c;
		}
		else
		{
			r = c;
			b = x;
		}
		return fromRGBf(r + m, g + m, b + m, a);
	}

	/** 
		Returns HSL components. Hue is zero for grayscale; alpha is omitted. 
	**/
	public function toHSL():{h:Float, s:Float, l:Float}
	{
		var r = rf;
		var g = gf;
		var b = bf;
		var max = Math.max(r, Math.max(g, b));
		var min = Math.min(r, Math.min(g, b));
		var delta = max - min;
		var l = (max + min) / 2;
		if (delta == 0)
			return {h: 0.0, s: 0.0, l: l};
		var h = if (max == r) ((g - b) / delta) % 6 else if (max == g) (b - r) / delta + 2 else (r - g) / delta + 4;
		return {h: wrapHue(h * 60), s: delta / (1 - Math.abs(2 * l - 1)), l: l};
	}

	/** 
		Returns an RGB/alpha blend. No gamma correction is applied. 
	**/
	public inline function interpolate(target:Color, ratio:Float):Color
	{
		ratio = clampUnit(ratio);
		var r = Math.round(ri + (target.ri - ri) * ratio);
		var g = Math.round(gi + (target.gi - gi) * ratio);
		var b = Math.round(bi + (target.bi - bi) * ratio);
		var a = Math.round(ai + (target.ai - ai) * ratio);
		return ratio == 0 ? new Color(this) : ratio == 1 ? target : fromRGBi(r, g, b, a);
	}

	/** 
		Same as interpolate.
	**/
	public inline function to(target:Color, ratio:Float):Color
		return interpolate(target, ratio);

	/** 
		Sets batch element rbg mults. 
	**/
	public inline function colorizeBatchElement(e:h2d.SpriteBatch.BatchElement, ratio:Float):Void
	{
		ratio = clampUnit(ratio);
		e.r = 1 + (rf - 1) * ratio;
		e.g = 1 + (gf - 1) * ratio;
		e.b = 1 + (bf - 1) * ratio;
	}

	/** 
		Allocates a normalized RGBA vector. 
	**/
	public inline function toVector4():h3d.Vector4
	{
		return new h3d.Vector4(rf, gf, bf, af);
	}

	/**
		Allocates a normalized RGB vector.
	**/
	public inline function toVector3():h3d.Vector
	{
		return new h3d.Vector(rf, gf, bf);
	}

	/** 
		Returns a copy with replaced alpha. 
	**/
	public inline function withAlpha(alpha:Float):Color
	{
		return fromRGBi(ri, gi, bi, toByte(alpha));
	}

	private static inline function clampByte(value:Int):Int
	{
		return value < 0 ? 0 : value > 255 ? 255 : value;
	}

	private static inline function clampUnit(value:Float):Float
	{
		return Math.isNaN(value) || value < 0 ? 0 : value > 1 ? 1 : value;
	}

	private static inline function toByte(value:Float):Int
	{
		return Math.round(clampUnit(value) * 255);
	}

	private static function wrapHue(value:Float):Float
	{
		if (!Math.isFinite(value))
			return 0;
		var wrapped = value % 360;
		return wrapped < 0 ? wrapped + 360 : wrapped;
	}

	inline function get_ai():Int
	{
		return (this >>> 24) & 0xFF;
	}

	inline function get_ri():Int
	{
		return (this >>> 16) & 0xFF;
	}

	inline function get_gi():Int
	{
		return (this >>> 8) & 0xFF;
	}

	inline function get_bi():Int
	{
		return this & 0xFF;
	}

	inline function set_ai(value:Int):Int
	{
		this = fromRGBi(ri, gi, bi, value);
		return get_ai();
	}

	inline function set_ri(value:Int):Int
	{
		this = fromRGBi(value, gi, bi, ai);
		return get_ri();
	}

	inline function set_gi(value:Int):Int
	{
		this = fromRGBi(ri, value, bi, ai);
		return get_gi();
	}

	inline function set_bi(value:Int):Int
	{
		this = fromRGBi(ri, gi, value, ai);
		return get_bi();
	}

	inline function get_af():Float
	{
		return ai / 255;
	}

	inline function get_rf():Float
	{
		return ri / 255;
	}

	inline function get_gf():Float
	{
		return gi / 255;
	}

	inline function get_bf():Float
	{
		return bi / 255;
	}

	inline function set_af(value:Float):Float
	{
		set_ai(toByte(value));
		return get_af();
	}

	inline function set_rf(value:Float):Float
	{
		set_ri(toByte(value));
		return get_rf();
	}

	inline function set_gf(value:Float):Float
	{
		set_gi(toByte(value));
		return get_gf();
	}

	inline function set_bf(value:Float):Float
	{
		set_bi(toByte(value));
		return get_bf();
	}

	function get_hue():Float
	{
		return toHSL().h;
	}

	function get_sat():Float
	{
		return toHSL().s;
	}

	function get_light():Float
	{
		return toHSL().l;
	}

	inline function set_hue(value:Float):Float
	{
		var hsl = toHSL();
		this = fromHSL(value, hsl.s, hsl.l, af);
		return get_hue();
	}

	inline function set_sat(value:Float):Float
	{
		var hsl = toHSL();
		this = fromHSL(hsl.h, value, hsl.l, af);
		return get_sat();
	}

	inline function set_light(value:Float):Float
	{
		var hsl = toHSL();
		this = fromHSL(hsl.h, hsl.s, value, af);
		return get_light();
	}
}
