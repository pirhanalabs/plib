package plib.engine.nodes.menu;

import haxe.ds.ObjectMap;
import plib.M;
import plib.engine.nodes.VisualNode;
import plib.types.Direction;
import plib.types.Signal;

/** Owns menu groups and coordinates focus, navigation, activation, and repeat. **/
class MenuContainerNode extends VisualNode
{
	public var active(default, set):Bool = true;
	public var mouseEnabled:Bool = true;
	public var mouseFocuses:Bool = true;
	public var repeatDelay:Float = 0.35;
	public var repeatInterval:Float = 0.08;
	public var preferHorizontalDiagonals:Bool = false;

	public var focusedGroup(default, null):Null<MenuGroupNode>;
	public var focusedElement(default, null):Null<MenuElementNode>;
	public final onFocusChanged:Signal<Null<MenuElementNode>> = new Signal();
	public final onUseFailed:Signal<MenuElementNode> = new Signal();

	private var cancelCallback:Null<Void->Bool>;
	private var heldDirection:Direction = Direction.Center;
	private var repeatElapsed:Float = 0;
	private var nextRepeat:Float = 0;

	/** Creates a menu root; add groups as direct children and feed it navigation in preupdate. **/
	public function new(?display:h2d.Object, ?cancelCallback:Void->Bool)
	{
		super(display);
		this.cancelCallback = cancelCallback;
	}

	/** Adds a direct navigation group and returns it. **/
	public function addGroup<T:MenuGroupNode>(group:T):T
		return add(group);

	/** Returns a snapshot of direct child groups in node order. **/
	public function groups():Array<MenuGroupNode>
	{
		var result = [];
		for (child in childIterator())
			if (Std.isOfType(child, MenuGroupNode))
				result.push(cast child);
		return result;
	}

	/** Enables interaction and focuses the requested target or first available element. **/
	public function activate(?group:MenuGroupNode, ?element:MenuElementNode):Bool
	{
		active = true;
		if (element != null)
			return focus(element);
		if (group != null)
			return focusGroup(group);
		validateFocus();
		return focusedElement != null || focusFirstGroup();
	}

	/** Disables interaction, clears focus, and resets held-direction repeat. **/
	public function deactivate()
	{
		active = false;
		clearFocus();
		resetRepeat();
	}

	/** Focuses an available element in a direct child group, preferring `preferred`. **/
	public function focusGroup(group:MenuGroupNode, ?preferred:MenuElementNode):Bool
	{
		if (!active || group == null || group.parent != this || !group.enabled)
			return false;
		var element = preferred;
		if (element == null || element.parent != group || !element.canFocus())
			element = group.preferred();
		return element != null && focus(element);
	}

	/** Focuses an available element owned by this menu; returns false for invalid targets. **/
	public function focus(element:MenuElementNode):Bool
	{
		if (!active || element == null || !element.canFocus())
			return false;
		var group = element.parent;
		if (!Std.isOfType(group, MenuGroupNode))
			return false;
		var typedGroup:MenuGroupNode = cast group;
		if (typedGroup.parent != this || !typedGroup.enabled)
			return false;
		if (focusedElement == element)
			return true;

		var previous = focusedElement;
		focusedElement = element;
		focusedGroup = typedGroup;
		typedGroup.remember(element);
		if (previous != null)
			previous.setFocused(false);
		element.setFocused(true);
		onFocusChanged.dispatch(element);
		return true;
	}

	/** Moves once in a cardinal direction, following group links before wrapping. **/
	public function move(direction:Direction):Bool
	{
		if (!active)
			return false;
		direction = cardinalize(direction);
		if (direction == Direction.Center)
			return false;
		validateFocus();
		if (focusedElement == null && !focusFirstGroup())
			return false;

		var group = focusedGroup;
		var element = focusedElement;
		var internal = group.moveFrom(element, direction, false);
		if (internal != null)
			return focus(internal);

		var visited:ObjectMap<MenuGroupNode, Bool> = new ObjectMap();
		visited.set(group, true);
		var linked = group.linked(direction);
		while (linked != null && !visited.exists(linked))
		{
			visited.set(linked, true);
			if (linked.parent == this && linked.enabled)
			{
				var preferred = linked.preferred();
				if (preferred != null)
					return focus(preferred);
			}
			linked = linked.linked(direction);
		}

		var wrapped = group.moveFrom(element, direction, true);
		return wrapped != null && focus(wrapped);
	}

	/** Applies initial movement and delayed repeat from aggregated player directions. **/
	public function navigate(pressed:Direction, down:Direction, dt:Float):Bool
	{
		if (!active)
			return false;
		pressed = cardinalize(pressed);
		down = cardinalize(down);
		if (pressed != Direction.Center)
		{
			heldDirection = down == Direction.Center ? pressed : down;
			repeatElapsed = 0;
			nextRepeat = repeatDelay;
			return move(pressed);
		}
		if (down == Direction.Center)
		{
			resetRepeat();
			return false;
		}
		if (down != heldDirection)
		{
			heldDirection = down;
			repeatElapsed = 0;
			nextRepeat = repeatDelay;
			return move(down);
		}
		repeatElapsed += M.max(0.0, dt);
		if (repeatElapsed < nextRepeat)
			return false;
		nextRepeat += M.max(0.001, repeatInterval);
		return move(down);
	}

	/** Activates the focused element and reports whether its action succeeded. **/
	public function use():Bool
	{
		validateFocus();
		var element = focusedElement;
		if (!active || element == null)
			return false;
		var succeeded = element.use();
		if (!succeeded)
			onUseFailed.dispatch(element);
		return succeeded;
	}

	/** Invokes the configured cancel action when active and returns its success value. **/
	public function cancel():Bool
		return active && cancelCallback != null && cancelCallback();

	/** Replaces or clears the cancel action and returns this menu for chaining. **/
	public function setCancelCallback(callback:Null<Void->Bool>):MenuContainerNode
	{
		cancelCallback = callback;
		return this;
	}

	@:allow(plib.engine.nodes.menu.MenuElementNode)
	private function mouseFocus(element:MenuElementNode)
	{
		if (mouseEnabled && mouseFocuses)
			focus(element);
	}

	@:allow(plib.engine.nodes.menu.MenuElementNode)
	private function mousePress(element:MenuElementNode)
	{
		if (!mouseEnabled || !focus(element))
			return;
		element.setPressed(true);
	}

	@:allow(plib.engine.nodes.menu.MenuElementNode)
	private function mouseRelease(element:MenuElementNode, inside:Bool)
	{
		if (!element.pressed)
			return;
		element.setPressed(false);
		if (mouseEnabled && inside && focusedElement == element)
			use();
	}

	@:allow(plib.engine.nodes.menu.MenuElementNode)
	private function validateFocus()
	{
		if (focusedElement != null
			&& focusedGroup != null
			&& focusedElement.parent == focusedGroup
			&& focusedGroup.parent == this
			&& focusedGroup.enabled
			&& focusedElement.canFocus())
			return;
		var oldGroup = focusedGroup;
		clearFocus();
		if (oldGroup != null && oldGroup.parent == this && focusGroup(oldGroup))
			return;
		focusFirstGroup();
	}

	private function focusFirstGroup():Bool
	{
		for (group in groups())
			if (focusGroup(group))
				return true;
		return false;
	}

	private function clearFocus()
	{
		var previous = focusedElement;
		focusedElement = null;
		focusedGroup = null;
		if (previous != null)
			previous.setFocused(false);
		if (previous != null)
			onFocusChanged.dispatch(null);
	}

	private function cardinalize(direction:Direction):Direction
	{
		if (direction.dx == 0 || direction.dy == 0)
			return direction;
		return preferHorizontalDiagonals ? Direction.from(direction.dx, 0) : Direction.from(0, direction.dy);
	}

	private function resetRepeat()
	{
		heldDirection = Direction.Center;
		repeatElapsed = 0;
		nextRepeat = 0;
	}

	private function set_active(value:Bool):Bool
	{
		active = value;
		if (!value)
			resetRepeat();
		return value;
	}

	override function preupdate()
	{
		super.preupdate();
		if (active)
			validateFocus();
	}
}
