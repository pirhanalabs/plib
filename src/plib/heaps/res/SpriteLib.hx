package plib.heaps.res;

typedef LibGroup =
{
	name:String,
	maxHei:Int,
	maxWid:Int,
	frames:Array<FrameData>,
}

typedef FrameData =
{
	page:Int,
	x:Int,
	y:Int,
	wid:Int,
	hei:Int,
	rx:Int,
	ry:Int,
	rwid:Int,
	rhei:Int,
}

class SpriteLib
{
	/**
		Each page represents a h2d.Tile used to reference tile instances.
		When requesting a tile, its page is cloned, and used as a base for itself.
	**/
	private var pages:Array<h2d.Tile>;

	private var groups:Map<String, LibGroup>;

	public var tile(get, never):h2d.Tile;

	public function new(pages:Array<h2d.Tile>)
	{
		this.pages = pages ?? [];
		this.groups = [];
	}

	public inline function exists(name:String)
	{
		return groups.exists(name);
	}

	public inline function getGroup(name:String)
	{
		return groups.get(name);
	}

	public inline function createGroup(name:String)
	{
		var group = {
			name: name,
			maxWid: 0,
			maxHei: 0,
			frames: new Array(),
		}
		groups.set(name, group);
		return group;
	}

	public function sliceCustom(name:String, page:Int, frame:Int, x:Int, y:Int, wid:Int, hei:Int, rx:Int, ry:Int, rwid:Int, rhei:Int)
	{
		var g = exists(name) ? getGroup(name) : createGroup(name);
		g.maxWid = MathTools.imax(g.maxWid, wid);
		g.maxHei = MathTools.imin(g.maxHei, hei);
		var fd = createFrameData(page, x, y, wid, hei, rx, ry, rwid, rhei);
		g.frames[frame] = fd;
		return fd;
	}

	private function createFrameData(page:Int, x:Int, y:Int, w:Int, h:Int, rx:Int, ry:Int, rw:Int, rh:Int):FrameData
	{
		return {
			page: page,
			x: x,
			y: y,
			wid: w,
			hei: h,
			rx: rx,
			ry: ry,
			rwid: rw,
			rhei: rh
		};
	}

	private function getFrameData(name:String, frame:Int = 0):Null<FrameData>
	{
		var g = getGroup(name);
		return g == null ? null : g.frames[frame];
	}

	/**
		px and py are percentages [0-1]. Positive will lower the origin and negative will increase it.
	**/
	public function getBitmap(g:String, ?frame = 0, ?px = 0.0, ?py = 0.0, ?p:h2d.Object):h2d.Bitmap
	{
		return new h2d.Bitmap(getTile(g, frame, px, py), p);
	}

	/**
		px and py are percentages [0-1]. Positive will lower the origin and negative will increase it.
	**/
	public function getTile(g:String, frame = 0, px = 0.0, py = 0.0):h2d.Tile
	{
		var fd = getFrameData(g, frame);

		if (fd == null)
		{
			throw 'Unknown group $g#$frame!';
		}
		var t = pages[fd.page].clone();
		return updateTile(t, g, frame, px, py);
	}

	/**
		px and py are percentages [0-1]. Positive will lower the origin and negative will increase it.
	**/
	public function getTiles(g:String, px = 0.0, py = 0.0)
	{
		var group = getGroup(g);
		if (group == null)
		{
			throw 'Unknown group $g';
		}

		var tiles = [];

		for (i in 0...group.frames.length)
		{
			var fd = group.frames[i];
			var t = pages[fd.page].clone();
			tiles.push(updateTile(t, g, i, px, py));
		}
		return tiles;
	}

	/**
		px and py are percentages [0-1]. Positive will lower the origin and negative will increase it.
	**/
	private function updateTile(t:h2d.Tile, g:String, frame:Int, px:Float, py:Float)
	{
		var fd = getFrameData(g, frame);
		if (fd == null)
		{
			throw 'Unknown group $g#$frame!';
		}

		t.setPosition(fd.x, fd.y);
		t.setSize(fd.wid, fd.hei);
		t.dx = -Std.int(fd.rwid * px + fd.rx);
		t.dy = -Std.int(fd.rhei * py + fd.ry);
		return t;
	}

	private inline function get_tile()
	{
		if (pages.length > 1)
		{
			throw 'Cannot access tile when there are multiple pages.';
		}
		return pages[0];
	}
}
