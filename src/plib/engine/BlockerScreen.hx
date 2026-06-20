package plib.engine;

class BlockerScreen extends plib.engine.Screen
{
	private var blocker:h2d.Interactive;
	private var inner:h2d.Layers;

	public function new()
	{
		super();
		blocker = null;
		inner = null;
	}

	override function ready()
	{
		super.ready();
		blocker = new h2d.Interactive(app.vw, app.vh);
		blocker.cursor = Default;
		inner = new h2d.Layers();

		root.add(blocker, 1);
		root.add(inner, 1);
	}

	private function getMousePoint()
	{
		final mx = app.window.mouseX;
		final my = app.window.mouseY;
		return inner.globalToLocal(new h2d.col.Point(mx, my));
	}
}
