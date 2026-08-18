package plib.engine.nodes;

import plib.M;

/** Stable logical and fitted physical dimensions used by presentation layers. **/
class ViewportMetrics
{
	public var wid(default, null):Int;
	public var hei(default, null):Int;
	public var centerX(default, null):Float;
	public var centerY(default, null):Float;
	public var physicalX(default, null):Float;
	public var physicalY(default, null):Float;
	public var physicalWid(default, null):Float;
	public var physicalHei(default, null):Float;
	public var scale(default, null):Float;
	public var revision(default, null):Int;
	public var referenceWid(default, null):Int;
	public var referenceHei(default, null):Int;
	public var integerScaling(default, null):Bool;

	private var windowBased:Bool;
	private var windowWid:Int;
	private var windowHei:Int;

	public function new(referenceWid:Int, referenceHei:Int, integerScaling:Bool = false)
	{
		this.windowBased = false;
		this.windowWid = 0;
		this.windowHei = 0;
		this.revision = 0;
		validateSize(referenceWid, referenceHei);
		this.referenceWid = referenceWid;
		this.referenceHei = referenceHei;
		this.integerScaling = integerScaling;
		setValues(referenceWid, referenceHei, 0, 0, 0, 0, 1);
	}

	/** Creates metrics that always map one logical unit to one window pixel. **/
	public static function forWindow():ViewportMetrics
	{
		var metrics = new ViewportMetrics(1, 1, false);
		metrics.windowBased = true;
		return metrics;
	}

	private static inline function validateSize(wid:Int, hei:Int)
	{
		if (wid <= 0 || hei <= 0)
			throw 'Viewport metric dimensions must be positive.';
	}

	@:allow(plib.engine.nodes.LayerNode)
	@:allow(plib.engine.nodes.LayersGroupNode)
	private function setReferenceSize(wid:Int, hei:Int)
	{
		if (windowBased)
			throw 'Physical window metrics cannot have a reference resolution.';
		validateSize(wid, hei);
		if (referenceWid == wid && referenceHei == hei)
			return;
		referenceWid = wid;
		referenceHei = hei;
		resizeWindow(windowWid, windowHei);
	}

	@:allow(plib.engine.nodes.LayerNode)
	@:allow(plib.engine.nodes.LayersGroupNode)
	private function setIntegerScaling(enabled:Bool)
	{
		if (windowBased)
			throw 'Physical window metrics cannot use integer fitting.';
		if (integerScaling == enabled)
			return;
		integerScaling = enabled;
		resizeWindow(windowWid, windowHei);
	}

	@:allow(plib.engine.nodes.LayersGroupNode)
	private function resizeWindow(wid:Int, hei:Int)
	{
		if (wid <= 0 || hei <= 0)
			return;
		windowWid = wid;
		windowHei = hei;
		if (windowBased)
		{
			setValues(wid, hei, 0, 0, wid, hei, 1);
			return;
		}

		var fit = M.min(wid / referenceWid, hei / referenceHei);
		var fittedScale = integerScaling && fit >= 1 ? M.floor(fit) : fit;
		var fittedWid = referenceWid * fittedScale;
		var fittedHei = referenceHei * fittedScale;
		setValues(referenceWid, referenceHei, (wid - fittedWid) * 0.5, (hei - fittedHei) * 0.5, fittedWid, fittedHei, fittedScale);
	}

	private function setValues(wid:Int, hei:Int, x:Float, y:Float, physicalWid:Float, physicalHei:Float, scale:Float)
	{
		if (this.wid == wid && this.hei == hei && physicalX == x && physicalY == y && this.physicalWid == physicalWid && this.physicalHei == physicalHei
			&& this.scale == scale)
			return;
		this.wid = wid;
		this.hei = hei;
		centerX = wid * 0.5;
		centerY = hei * 0.5;
		physicalX = x;
		physicalY = y;
		this.physicalWid = physicalWid;
		this.physicalHei = physicalHei;
		this.scale = scale;
		revision++;
	}
}

/** A fitted coordinate-space layer with ordered content and overlay mounts. **/
class LayerNode extends VisualNode
{
	public static inline final CONTENT_LAYER = 0;
	public static inline final OVERLAY_LAYER = 10;

	public var metrics(default, set):ViewportMetrics;
	public final layers:h2d.Layers;
	public final content:VisualNode;
	public final overlay:VisualNode;
	public var order(default, null):Int;

	private var owner:Null<LayersGroupNode>;
	private var transformDirty:Bool;
	private var orderDirty:Bool;

	public function new(metrics:ViewportMetrics)
	{
		if (metrics == null)
			throw 'LayerNode requires viewport metrics.';
		var display = new h2d.Layers();
		super(display);
		layers = display;
		this.metrics = metrics;
		this.order = 0;
		this.owner = null;
		this.transformDirty = true;
		this.orderDirty = true;
		content = add(new VisualNode());
		overlay = add(new VisualNode());
	}

	private function set_metrics(value:ViewportMetrics):ViewportMetrics
	{
		if (value == null)
			throw 'LayerNode metrics cannot be null.';
		if (metrics == value)
			return value;
		if (tree != null && tree.processing)
			throw 'Layer metrics cannot change while the NodeTree is processing.';
		if (owner != null)
			owner.validateMetricsAssignment(this);
		metrics = value;
		transformDirty = true;
		if (owner != null)
			owner.refreshMetrics(value);
		return value;
	}

	/** Changes the shared metrics reference resolution and refreshes every layer using it. **/
	public function setReferenceSize(wid:Int, hei:Int):LayerNode
	{
		validateConfigurationTiming();
		metrics.setReferenceSize(wid, hei);
		if (owner != null)
			owner.refreshMetrics(metrics);
		return this;
	}

	/** Changes the shared metrics fitting policy. **/
	public function setIntegerScaling(enabled:Bool):LayerNode
	{
		validateConfigurationTiming();
		metrics.setIntegerScaling(enabled);
		if (owner != null)
			owner.refreshMetrics(metrics);
		return this;
	}

	private inline function validateConfigurationTiming()
	{
		if (tree != null && tree.processing)
			throw 'Layer metrics cannot change while the NodeTree is processing.';
	}

	@:allow(plib.engine.nodes.LayersGroupNode)
	private function register(owner:LayersGroupNode, order:Int)
	{
		this.owner = owner;
		this.order = order;
		transformDirty = true;
		orderDirty = true;
	}

	@:allow(plib.engine.nodes.LayersGroupNode)
	private function markTransformDirty()
		transformDirty = true;

	override function provideViewportMetrics():Null<ViewportMetrics>
		return metrics;

	override function postupdate()
	{
		super.postupdate();
		if (orderDirty)
		{
			orderDirty = false;
			layers.add(content.display, CONTENT_LAYER);
			layers.add(overlay.display, OVERLAY_LAYER);
		}
		if (!transformDirty)
			return;
		transformDirty = false;
		display.x = metrics.physicalX;
		display.y = metrics.physicalY;
		display.scaleX = metrics.scale;
		display.scaleY = metrics.scale;
	}
}
