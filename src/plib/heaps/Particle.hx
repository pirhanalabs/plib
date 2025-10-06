package plib.heaps;

class Particle extends h2d.SpriteBatch.BatchElement
{
	public var killed:Bool;
	public var pool(default, null):ParticlePool;

	private var pool_idx:Int;
	private var stamp:Float;

	public var lifeS:Float;
	public var maxLifeS:Float;
	public var delayS:Float;

	public var dx:Float;
	public var dy:Float;
	public var frictX:Float;
	public var frictY:Float;

	public var fadeOutSpeed:Float;
	public var fadeInSpeed:Float;

	public var onStart:Void->Void;
	public var onUpdate:Particle->Void;

	public var gx:Float;
	public var gy:Float;

	public function new(pool:ParticlePool, tile:h2d.Tile)
	{
		super(tile);
		this.pool = pool;
		this.pool_idx = -1;
		this.killed = false;

		reset(null, x, y);
	}

	public inline function setLife(lifeS:Float)
	{
		this.maxLifeS = lifeS;
		this.lifeS = lifeS;
	}

	public inline function getLifeRatio()
	{
		return lifeS / maxLifeS;
	}

	private function reset(b:h2d.SpriteBatch, ?t:h2d.Tile, ?x:Float, ?y:Float)
	{
		if (batch != b)
		{
			if (batch != null)
			{
				remove();
			}
			if (b != null)
			{
				b.add(this);
			}
		}

		this.t = t ?? this.t;
		this.x = x;
		this.y = y;

		this.stamp = haxe.Timer.stamp();

		this.killed = false;
		this.alpha = 1;
		this.visible = true;
		this.delayS = 0;
		this.lifeS = 1;
		this.maxLifeS = 1;

		this.dx = 0;
		this.dy = 0;
		this.frictX = 1;
		this.frictY = 1;

		this.fadeInSpeed = 1;
		this.fadeOutSpeed = 1;

		this.gx = 0;
		this.gy = 0;

		this.onStart = null;
		this.onUpdate = null;
	}

	public function kill()
	{
		alpha = 0;
		lifeS = 0;
		delayS = 0;
		killed = true;
		visible = false;

		@:privateAccess pool.free(this);
	}

	public function clone():Particle
	{
		var s = new haxe.Serializer();
		s.useCache = true;
		s.serialize(this);
		return haxe.Unserializer.run(s.toString());
	}

	private function dispose()
	{
		reset(null);
		pool = null;
	}

	private function updatePart(frame:Frame)
	{
		var tmod = frame.tmod;

		delayS -= frame.dt;

		if (delayS <= 0 && !killed)
		{
			// start callback
			if (onStart != null)
			{
				var cb = onStart;
				onStart = null;
				cb();
			}
		}

		if (!killed)
		{
			// gravity
			dx += gx * tmod;
			dy += gy * tmod;

			// velocity
			x += dx * tmod;
			y += dy * tmod;

			// friction
			if (frictX == frictY)
			{
				var frictTmod = optimPow(frictX, tmod);
				dx *= frictTmod;
				dy *= frictTmod;
			}
			else
			{
				dx *= optimPow(frictX, tmod);
				dy *= optimPow(frictY, tmod);
			}

			// life
			lifeS -= frame.dt;

			if (lifeS <= 0)
			{
				alpha -= fadeOutSpeed * tmod;
			}

			if (lifeS <= 0 && (alpha <= 0))
			{
				kill();
			}
			else if (onUpdate != null)
			{
				onUpdate(this);
			}
		}
	}

	public inline function colorize(c:Color, ratio:Float)
	{
		c.colorizeBatchElement(this, ratio);
	}

	public inline function interpolateColor(c1:Color, c2:Color, r:Float)
	{
		var c = c1.interpolate(c2, r);
		colorize(c, 1);
	}

	private inline function optimPow(v:Float, p:Float)
	{
		return (p == 1 || v == 0 || v == 1) ? v : Math.pow(v, p);
	}

	public inline function moveTo(x:Float, y:Float, speed:Float)
	{
		var a = Math.atan2(y - this.y, x - this.y);
		dx = Math.cos(a) * speed;
		dy = Math.sin(a) * speed;
	}

	public inline function moveAwayFrom(x:Float, y:Float, speed:Float)
	{
		var a = Math.atan2(y - this.y, x - this.x);
		dx = -Math.cos(a) * speed;
		dy = -Math.sin(a) * speed;
	}
}
