package plib.engine.nodes;

import h2d.col.Point;

/** Node whose display parent mirrors the nearest visual hierarchy parent. **/
class VisualNode extends Node
{
	public final display:h2d.Object;

	public var x(get, set):Float;
	public var y(get, set):Float;

	public function new(?display:h2d.Object)
	{
		super();
		this.display = display == null ? new h2d.Object() : display;
	}

	inline function get_x():Float
	{
		return display.x;
	}

	inline function get_y():Float
	{
		return display.y;
	}

	inline function set_x(v:Float):Float
	{
		return display.x = v;
	}

	inline function set_y(v:Float):Float
	{
		return display.y = v;
	}

	override function onAddedToTree()
	{
		super.onAddedToTree();
		refreshVisualParent();
	}

	override function onRemovedFromTree()
	{
		display.remove();
		super.onRemovedFromTree();
	}

	override function onReparented(oldParent:Node, newParent:Node)
	{
		super.onReparented(oldParent, newParent);
		refreshVisualParent();
	}

	public function refreshVisualParent()
	{
		var visualParent = getVisualParent();
		if (visualParent != null)
		{
			visualParent.display.addChild(display);
			return;
		}
		if (tree != null && tree.visualRoot != null)
		{
			tree.visualRoot.addChild(display);
		}
	}

	/** Returns the closest logical ancestor that owns a display object. **/
	public function getVisualParent():Null<VisualNode>
	{
		var current = parent;
		while (current != null)
		{
			if (Std.isOfType(current, VisualNode))
				return cast current;
			current = current.parent;
		}
		return null;
	}

	/** Returns whether this node's display is a strict ancestor of `object`. **/
	public inline function containsDisplay(object:h2d.Object):Bool
	{
		return object != null && display.contains(object);
	}

	/** Returns whether this node's display is below `object` in the display tree. **/
	public function isDisplayDescendantOf(object:h2d.Object):Bool
	{
		return object != null && object.contains(display);
	}

	/**
		Converts the current scene mouse position into `target` coordinates.
		The node display is used when `target` is omitted.
	**/
	public function mouseToLocal(?target:h2d.Object):Point
	{
		if (target == null)
			target = display;
		var scene = target.getScene();
		if (scene == null)
			throw 'Cannot read the mouse position for a display outside an h2d.Scene.';
		return target.globalToLocal(new Point(scene.mouseX, scene.mouseY));
	}

	/** Returns whether the scene mouse is inside `target`'s recursive bounds. **/
	public function mouseInBounds(?target:h2d.Object):Bool
	{
		if (target == null)
			target = display;
		return target.getBounds(target).contains(mouseToLocal(target));
	}

	/**
		Converts `point` from `source` coordinates into `context` coordinates.
		The source origin and this node's display are used when omitted.
	**/
	public function sourceToLocal(source:h2d.Object, ?context:h2d.Object, ?point:Point):Point
	{
		if (source == null)
			throw 'Coordinate source cannot be null.';
		if (context == null)
			context = display;
		var converted = point == null ? new Point() : new Point(point.x, point.y);
		return context.globalToLocal(source.localToGlobal(converted));
	}

	public function hide()
	{
		pause();
		display.visible = false;
		onHide();
	}

	public function show()
	{
		resume();
		display.visible = true;
		onShow();
	}

	private function onHide() {}

	private function onShow() {}
}
