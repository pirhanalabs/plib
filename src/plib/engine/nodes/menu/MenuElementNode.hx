package plib.engine.nodes.menu;

import plib.engine.nodes.VisualNode;

/** Base visual node for one focusable menu element. Subclass it for real controls. **/
abstract class MenuElementNode extends VisualNode
{
	public final interactive:h2d.Interactive;
	public var enabled(default, set):Bool = true;
	public var selectable(default, set):Bool = true;
	public var mouseEnabled(default, set):Bool = true;
	public var focused(default, null):Bool = false;
	public var pressed(default, null):Bool = false;

	private var useCallback:Null<MenuElementNode->Bool>;

	/** Private prevents direct construction while remaining available to subclasses. **/
	private function new(?display:h2d.Object, ?useCallback:MenuElementNode->Bool)
	{
		super(display);
		this.useCallback = useCallback;
		interactive = new h2d.Interactive(0, 0, this.display);
		interactive.onMove = _ -> requestMouseFocus();
		interactive.onPush = _ -> requestMousePress();
		interactive.onRelease = _ -> requestMouseRelease(true);
		interactive.onReleaseOutside = _ -> requestMouseRelease(false);
		refreshInteraction();
	}

	public var visible(get, set):Bool;

	private inline function get_visible():Bool
		return display.visible;

	private function set_visible(value:Bool):Bool
	{
		if (display.visible == value)
			return value;
		display.visible = value;
		refreshInteraction();
		notifyAvailabilityChanged();
		onAvailabilityChanged();
		return value;
	}

	/** Reports whether this element is visible, enabled, and focusable. **/
	public inline function canFocus():Bool
		return visible && selectable;

	/** Attempts activation. Disabled elements deliberately return false. **/
	public function use():Bool
	{
		if (!canFocus() || !enabled)
			return false;
		return useCallback != null ? useCallback(this) : onUse();
	}

	/** Replaces the optional activation callback and returns this element. **/
	public function setUseCallback(callback:Null<MenuElementNode->Bool>):MenuElementNode
	{
		useCallback = callback;
		return this;
	}

	@:allow(plib.engine.nodes.menu.MenuContainerNode)
	private function setFocused(value:Bool)
	{
		if (focused == value)
			return;
		focused = value;
		if (!value)
			setPressed(false);
		if (value)
			onFocused()
		else
			onUnfocused();
	}

	@:allow(plib.engine.nodes.menu.MenuContainerNode)
	private function setPressed(value:Bool)
	{
		if (pressed == value)
			return;
		pressed = value;
		if (value)
			onPressed()
		else
			onReleased();
	}

	private function set_enabled(value:Bool):Bool
	{
		if (enabled == value)
			return value;
		enabled = value;
		onAvailabilityChanged();
		return value;
	}

	private function set_selectable(value:Bool):Bool
	{
		if (selectable == value)
			return value;
		selectable = value;
		refreshInteraction();
		notifyAvailabilityChanged();
		onAvailabilityChanged();
		return value;
	}

	private function set_mouseEnabled(value:Bool):Bool
	{
		mouseEnabled = value;
		refreshInteraction();
		return value;
	}

	private function refreshInteraction()
	{
		interactive.visible = visible && selectable && mouseEnabled;
		if (!interactive.visible)
			interactive.preventClick();
	}

	private function requestMouseFocus()
	{
		var menu = getMenu();
		if (menu != null)
			menu.mouseFocus(this);
	}

	private function requestMousePress()
	{
		var menu = getMenu();
		if (menu != null)
			menu.mousePress(this);
	}

	private function requestMouseRelease(inside:Bool)
	{
		var menu = getMenu();
		if (menu != null)
			menu.mouseRelease(this, inside);
	}

	private function notifyAvailabilityChanged()
	{
		var menu = getMenu();
		if (menu != null)
			menu.validateFocus();
	}

	/** Returns the owning menu when the element is correctly nested in a group. **/
	public function getMenu():Null<MenuContainerNode>
	{
		var current = parent;
		while (current != null)
		{
			if (Std.isOfType(current, MenuContainerNode))
				return cast current;
			current = current.parent;
		}
		return null;
	}

	/** Override to execute the element's action. **/
	public function onUse():Bool
		return false;

	/** Override to update visuals or audio after focus is gained. **/
	public function onFocused() {}

	/** Override to update visuals after focus is lost. **/
	public function onUnfocused() {}

	/** Override to show the pressed state. **/
	public function onPressed() {}

	/** Override to clear the pressed state. **/
	public function onReleased() {}

	/** Override to redraw enabled, visible, or focusable state changes. **/
	public function onAvailabilityChanged() {}
}
