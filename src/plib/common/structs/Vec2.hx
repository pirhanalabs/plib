package plib.common.structs;

class Vec2
{
	public var x:Float;
	public var y:Float;

	public function new(x:Float, y:Float)
	{
		this.x = x;
		this.y = y;
	}

	public function smoothdamp(to:Vec2, vel:Vec2, t:Float, d:Float, s:Float = M.FLOAT_MAX)
	{
		final velx = {v: vel.x};
		this.x = M.smoothdamp(x, to.x, velx, t, d, s);
		vel.x = velx.v;

		final vely = {v: vel.y};
		this.y = M.smoothdamp(y, to.y, vely, t, d, s);
		vel.y = vely.v;
	}

	public function smoothdamp_a(to:Vec2, t:Float, d:Float, s:Float = M.FLOAT_MAX)
	{
		var mag = M.sqrt(x * x + y * y);
		var tmag = M.sqrt(to.x * to.x + to.y * to.y);

		// avoid division by 0
		if (mag < 0.0001)
			mag = 0.0001;

		final acur = Math.atan2(y, x);
		final atrg = Math.atan2(to.y, to.x);

		final tmp = {v: 0.0};
		final na = M.smoothdamp_a(acur, atrg, tmp, t, d, s);

		x = Math.cos(na) * mag;
		y = Math.sin(na) * mag;
	}

	public function clone()
	{
		return new Vec2(x, y);
	}

	public inline function set(other:Vec2)
	{
		this.x = other.x;
		this.y = other.y;
	}

	public inline function add(other:Vec2):Vec2
	{
		return new Vec2(x + other.x, y + other.y);
	}

	public inline function sub(other:Vec2):Vec2
	{
		return new Vec2(x - other.x, y - other.y);
	}

	public inline function mult(other:Vec2):Vec2
	{
		return new Vec2(x * other.x, y * other.y);
	}

	public inline function divide(other:Vec2):Vec2
	{
		final xx = x == 0 ? 0 : x / other.x;
		final yy = y == 0 ? 0 : y / other.y;
		return new Vec2(xx, y / yy);
	}

	/**
		Adds another vector to this vector.
	**/
	public inline function add_ip(other:Vec2)
	{
		this.x += other.x;
		this.y += other.y;
	}

	/**
		Substracts another vector to this vector.
	**/
	public inline function sub_ip(other:Vec2)
	{
		this.x -= other.x;
		this.y -= other.y;
	}

	/**
		Multiplies this vector by another vector.
	**/
	public inline function mult_ip(other:Vec2)
	{
		this.x *= other.x;
		this.y *= other.y;
	}

	/**
		Divides this vector by another vector.
	**/
	public inline function divide_ip(other:Vec2)
	{
		final xx = x == 0 ? 0 : x / other.x;
		final yy = y == 0 ? 0 : y / other.y;
		this.x = xx;
		this.y = yy;
	}

	/**
		Returns the squared length (no sqrt).
	**/
	public inline function lengthSq()
	{
		return x * x + y * y;
	}

	/**
		Returns the vector length.
	**/
	public inline function length()
	{
		return M.sqrt(x * x + y * y);
	}

	/**
		Returns a new normalized vector.
		If length is ~0, returns (0,0).
	**/
	public function normalize():Vec2
	{
		final len = M.sqrt(x * x + y * y);

		if (len <= 1e-8)
			return new Vec2(0, 0);

		final inv = 1.0 / len;
		return new Vec2(x * inv, y * inv);
	}

	/**
		Normailizes this vector.
		If length is ~0, returns (0,0).
	**/
	public function normalize_ip():Vec2
	{
		final len = Math.sqrt(x * x + y * y);
		if (len <= 1e-8)
		{
			x = 0;
			y = 0;
			return this;
		}

		final inv = 1.0 / len;
		x *= inv;
		y *= inv;
		return this;
	}

	public function toString()
	{
		return 'Vector[x:${x}, y:${y}]';
	}
}
