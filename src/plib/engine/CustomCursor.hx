package plib.engine;

class CustomCursor
{
	public var smoothing:Float = 0.45;
	public var enabled:Bool;

	public var prev_x(default, null):Float;
	public var prev_y(default, null):Float;

	public var x(default, null):Float;
	public var y(default, null):Float;

	private var delta_x:Float;
	private var delta_y:Float;

	@:allow(engine.IApplication)
	private var cursor:h2d.Object;

	public function new()
	{
		cursor = new h2d.Object();
		enabled = true;
		this.x = 0;
		this.y = 0;
		this.prev_x = 0;
		this.prev_y = 0;
		this.delta_x = 0;
		this.delta_y = 0;
	}

	public function getCursor()
	{
		return cursor;
	}

	public function setCursor(o:h2d.Object)
	{
		this.cursor.removeChildren();
		this.cursor.addChild(o);
	}

	public function enable(val:Bool)
	{
		this.cursor.visible = val;
		this.enabled = val;

		if (enabled)
		{
			#if (sys || hl)
			// should probably do some validation work here.
			hxd.System.setCursor = function(c:hxd.Cursor)
			{
				hxd.System.setNativeCursor(Hide);
			}
			hxd.System.setCursor(Hide);
			#end
		}
		else
		{
			#if (sys || hl)
			// should probably do some validation work here.
			hxd.System.setCursor = function(c:hxd.Cursor)
			{
				hxd.System.setNativeCursor(c);
			}
			hxd.System.setCursor(Default);
			#end
		}
	}

	@:allow(engine.IApplication)
	private function onMove(e:hxd.Event)
	{
		setCursorPosition(e.relX, e.relY);
	}

	/** x/y must be global positions. **/
	@:allow(engine.IApplication)
	private function setCursorPosition(_x:Float, _y:Float)
	{
		if (cursor.parent == null)
			return;
		var point = cursor.parent.globalToLocal(new h2d.col.Point(_x, _y));
		this.prev_x = this.x;
		this.prev_y = this.y;
		this.x = point.x;
		this.y = point.y;
	}

	@:allow(engine.IApplication)
	private function onResize(scale:Float)
	{
		this.cursor.setScale(Std.int(scale));
	}

	@:allow(engine.IApplication)
	private function update(frame:engine.Frame)
	{
		var distx = this.x - this.cursor.x;
		var disty = this.y - this.cursor.y;
		delta_x = distx * smoothing * frame.tmod;
		delta_y = disty * smoothing * frame.tmod;
	}

	@:allow(engine.IApplication)
	private function postupdate()
	{
		this.cursor.x += delta_x;
		this.cursor.y += delta_y;
	}
}
