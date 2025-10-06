package plib.heaps;

class ParticlePool
{
	private var particles:haxe.ds.Vector<Particle>;
	private var nalloc:Int;

	public function new(tile:h2d.Tile)
	{
		particles = new haxe.ds.Vector(1048);
		nalloc = 0;

		for (i in 0...particles.length)
		{
			var p = new Particle(this, tile);
			particles.set(i, p);
		}
	}

	public function alloc(b:h2d.SpriteBatch, t:h2d.Tile, x:Float, y:Float)
	{
		if (nalloc < particles.length)
		{
			var p = particles.get(nalloc);
			@:privateAccess p.pool_idx = nalloc;
			@:privateAccess p.reset(b, t, x, y);
			nalloc++;
			return p;
		}

		var best:Particle = null;

		for (i in 0...nalloc)
		{
			if (best == null || @:privateAccess particles[i].stamp < @:privateAccess best.stamp)
			{
				best = particles[i];
			}
		}
		return best;
	}

	/**
		Call this when a particle is killed.
	**/
	public function free(p:Particle)
	{
		if (particles != null)
		{
			if (nalloc > 1)
			{
				var idx = @:privateAccess p.pool_idx;
				var tmp = particles[idx];
				particles[idx] = particles[nalloc - 1];
				@:privateAccess particles[idx].pool_idx = idx;
				particles[nalloc - 1] = tmp;
				nalloc--;
			}
			else
			{
				nalloc = 0;
			}
		}
	}

	/** Destroy every active particle **/
	public function clear()
	{
		var p:Particle = null;

		for (i in 0...particles.length)
		{
			p = particles[i];
			@:privateAccess p.reset(null);
			p.visible = false;
		}
	}

	public function dispose()
	{
		for (p in particles)
		{
			@:privateAccess p.dispose();
		}
		particles = null;
	}

	public function update(frame:Frame)
	{
		var i = 0;
		var p:Particle = null;
		while (i < nalloc)
		{
			p = particles[i];
			@:privateAccess p.updatePart(frame);

			if (!p.killed)
			{
				i++;
			}
		}
	}
}
