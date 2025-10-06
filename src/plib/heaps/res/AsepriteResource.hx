package plib.heaps.res;

class AsepriteResource
{
	// regex used for leading trail numbers
	static final regex = ~/([a-z0-9_]*?)(_*)([0-9]+)$/i;

	public var ase:aseprite.Aseprite;
	public var slib:SpriteLib;

	public var tile(get, never):h2d.Tile;

	/**
		Wraps an aseprite object and its associated sprite library.
		This is meant to add extra functionality to the slib, such as easy object creation.
	**/
	public function new(ase:aseprite.Aseprite)
	{
		this.ase = ase;

		// -- parse aseprite into a sprite library --

		slib = new SpriteLib([ase.toTile()]);

		// handle slices
		for (slice in ase.slices)
		{
			var s = ase.getSlice(slice.name);
			var t = s.tile;

			// slice using the original name
			slib.sliceCustom(slice.name, 0, 0, t.ix, t.iy, t.iwidth, t.iheight, 0, 0, t.iwidth, t.iheight);

			if (regex.match(slice.name))
			{
				slib.sliceCustom(regex.matched(1), 0, Std.parseInt(regex.matched(3)), t.ix, t.iy, t.iwidth, t.iheight, 0, 0, t.iwidth, t.iheight);
			}
		}
	}

	public inline function getAnimArray(name:String, frames:Array<Int>, px:Float, py:Float)
	{
		final tiles = getTiles(name, px, py);

		final anim = [];

		for (i in frames)
		{
			anim.push(tiles[i]);
		}

		return anim;
	}

	/**
		px and py are percentages [0-1]. Positive will lower the origin and negative will increase it.
	**/
	public inline function getTiles(name:String, px = 0.0, py = 0.0)
	{
		return slib.getTiles(name, px, py);
	}

	public inline function getBitmap(name:String)
	{
		return slib.getBitmap(name);
	}

	public inline function getTile(name:String, px = 0.0, py = 0.0)
	{
		return slib.getTile(name, 0, px, py);
	}

	public function getScaleGrid(name:String)
	{
		var slice = ase.slices.get(name);
		if (slice == null || !slice.has9Slices)
		{
			trace('WARNING: A slice named "${name}" does not exist or does not have 9-Slices enabled.');
			return new h2d.ScaleGrid(null, 0, 0);
		}
		var sliceKey = slice.keys[0];

		var tile = slib.getTile(name);

		var scalegrid = new h2d.ScaleGrid(tile, sliceKey.xCenter, sliceKey.yCenter);
		return scalegrid;
	}

	private inline function get_tile()
	{
		return slib.tile;
	}
}
