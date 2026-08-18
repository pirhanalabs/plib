package plib.engine.nodes;

import plib.engine.nodes.LayerNode.ViewportMetrics;

/** Presentation applied outside the fitted world rectangle. **/
enum ViewportBorderMode
{
	None;
	Solid(color:Int, alpha:Float);
}

/** Unscaled owner and compositor for world, HUD, and physical-window layers. **/
class LayersGroupNode extends VisualNode
{
	public static inline final WORLD_LAYER = 0;
	public static inline final HUD_LAYER = 10;
	public static inline final WINDOW_LAYER = 20;
	private static inline final BORDER_LAYER = 20;

	public final layers:h2d.Layers;
	public final world:LayerNode;
	public final hud:LayerNode;
	public final window:LayerNode;
	public var borderMode(default, null):ViewportBorderMode;

	private final layerList:Array<LayerNode>;
	private final borderDisplay:VisualNode;
	private var borderGraphics:Null<h2d.Graphics>;
	private var windowWid:Int;
	private var windowHei:Int;
	private var layerOrderDirty:Bool;
	private var bordersDirty:Bool;

	public function new(referenceWid:Int, referenceHei:Int, integerScaling:Bool = false, ?borderMode:ViewportBorderMode)
	{
		var display = new h2d.Layers();
		super(display);
		layers = display;
		layerList = [];
		windowWid = 0;
		windowHei = 0;
		layerOrderDirty = true;
		bordersDirty = true;
		this.borderMode = borderMode == null ? Solid(0x000000, 1) : borderMode;

		var worldMetrics = new ViewportMetrics(referenceWid, referenceHei, integerScaling);
		var windowMetrics = ViewportMetrics.forWindow();
		world = addLayer(new LayerNode(worldMetrics), WORLD_LAYER);
		hud = addLayer(new LayerNode(worldMetrics), HUD_LAYER);
		window = addLayer(new LayerNode(windowMetrics), WINDOW_LAYER);
		borderDisplay = window.add(new VisualNode());
		borderGraphics = null;
	}

	/** Adds a retained custom top-level layer without maintaining a key registry. **/
	public function addLayer(layer:LayerNode, order:Int):LayerNode
	{
		if (layer == null)
			throw 'Cannot add a null presentation layer.';
		if (layer.parent != null || layer.tree != null || layer.state != Detached)
			throw 'Only detached presentation layers can be added.';
		layer.register(this, order);
		layerList.push(layer);
		add(layer);
		layerOrderDirty = true;
		if (windowWid > 0)
			refreshMetrics(layer.metrics);
		return layer;
	}

	/** Recalculates every unique metrics object against the physical window. **/
	public function resize(windowWid:Int, windowHei:Int)
	{
		if (windowWid <= 0 || windowHei <= 0)
			return;
		this.windowWid = windowWid;
		this.windowHei = windowHei;
		var updated = new haxe.ds.ObjectMap<ViewportMetrics, Bool>();
		for (layer in layerList)
		{
			if (!updated.exists(layer.metrics))
			{
				updated.set(layer.metrics, true);
				layer.metrics.resizeWindow(windowWid, windowHei);
			}
			layer.markTransformDirty();
		}
		bordersDirty = true;
	}

	@:allow(plib.engine.nodes.LayerNode)
	private function validateMetricsAssignment(layer:LayerNode)
	{
		if (layer == window)
			throw 'The window layer must retain physical window metrics.';
	}

	@:allow(plib.engine.nodes.LayerNode)
	private function refreshMetrics(metrics:ViewportMetrics)
	{
		if (windowWid > 0)
			metrics.resizeWindow(windowWid, windowHei);
		for (layer in layerList)
			if (layer.metrics == metrics)
				layer.markTransformDirty();
		bordersDirty = true;
		if (tree != null)
			tree.resize();
	}

	public function setBorderMode(mode:ViewportBorderMode)
	{
		if (mode == null)
			throw 'Border mode cannot be null.';
		if (Type.enumEq(borderMode, mode))
			return;
		borderMode = mode;
		bordersDirty = true;
	}

	override function postupdate()
	{
		super.postupdate();
		if (layerOrderDirty)
		{
			layerOrderDirty = false;
			for (layer in layerList)
				layers.add(layer.display, layer.order);
			window.layers.add(borderDisplay.display, BORDER_LAYER);
		}
		if (!bordersDirty)
			return;
		bordersDirty = false;
		if (borderGraphics == null && tree != null && tree.visualRoot != null)
			borderGraphics = new h2d.Graphics(borderDisplay.display);
		redrawBorders();
	}

	private function redrawBorders()
	{
		if (borderGraphics == null)
			return;
		borderGraphics.clear();
		switch borderMode
		{
			case None:
			case Solid(color, alpha):
				var metrics = world.metrics;
				var x = metrics.physicalX;
				var y = metrics.physicalY;
				var wid = metrics.physicalWid;
				var hei = metrics.physicalHei;
				borderGraphics.beginFill(color, alpha);
				if (x > 0)
				{
					borderGraphics.drawRect(0, 0, x, windowHei);
					borderGraphics.drawRect(x + wid, 0, windowWid - x - wid, windowHei);
				}
				if (y > 0)
				{
					borderGraphics.drawRect(x, 0, wid, y);
					borderGraphics.drawRect(x, y + hei, wid, windowHei - y - hei);
				}
				borderGraphics.endFill();
		}
	}
}
