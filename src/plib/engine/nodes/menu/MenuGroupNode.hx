package plib.engine.nodes.menu;

import plib.M;
import plib.engine.nodes.Node;
import plib.types.Direction;

enum MenuLayout
{
	Vertical;
	Horizontal;
	Grid(columns:Int);
}

/** Ordered navigation group containing direct `MenuElementNode` children. **/
class MenuGroupNode extends Node
{
	public var layout(default, set):MenuLayout;
	public var enabled:Bool = true;
	public var wrapHorizontal:Bool = false;
	public var wrapVertical:Bool = false;
	public var lastFocused(default, null):Null<MenuElementNode>;

	private final links:Map<Int, MenuGroupNode> = [];

	/** Creates a group whose direct element children navigate using `layout`. **/
	public function new(layout:MenuLayout)
	{
		super();
		this.layout = validateLayout(layout);
	}

	/** Adds a direct menu element and returns it. **/
	public function addElement<T:MenuElementNode>(element:T):T
		return add(element);

	/** Returns direct element children in node order. **/
	public function elements():Array<MenuElementNode>
	{
		var result = [];
		for (child in childIterator())
			if (Std.isOfType(child, MenuElementNode))
				result.push(cast child);
		return result;
	}

	/** Sets the group entered when navigation exhausts items in `direction`. **/
	public function link(direction:Direction, group:MenuGroupNode):MenuGroupNode
	{
		validateLink(direction, group);
		links.set(cast direction, group);
		return this;
	}

	/** Links both groups using `direction` and its opposite. **/
	public function linkBoth(direction:Direction, group:MenuGroupNode):MenuGroupNode
	{
		link(direction, group);
		group.link(Direction.from(-direction.dx, -direction.dy), this);
		return this;
	}

	/** Removes one directional link and reports whether it existed. **/
	public function unlink(direction:Direction):Bool
		return links.remove(cast direction);

	/** Returns the group linked in a cardinal direction, if any. **/
	public function linked(direction:Direction):Null<MenuGroupNode>
		return links.get(cast direction);

	@:allow(plib.engine.nodes.menu.MenuContainerNode)
	private function remember(element:MenuElementNode)
	{
		if (element != null && element.parent == this)
			lastFocused = element;
	}

	@:allow(plib.engine.nodes.menu.MenuContainerNode)
	private function preferred():Null<MenuElementNode>
	{
		if (lastFocused != null && lastFocused.parent == this && lastFocused.canFocus())
			return lastFocused;
		for (element in elements())
			if (element.canFocus())
				return element;
		return null;
	}

	@:allow(plib.engine.nodes.menu.MenuContainerNode)
	private function moveFrom(current:MenuElementNode, direction:Direction, allowWrap:Bool):Null<MenuElementNode>
	{
		var values = elements();
		var index = values.indexOf(current);
		if (index < 0 || values.length == 0)
			return null;
		return switch layout
		{
			case Vertical: moveLinear(values, index, direction.dy, allowWrap && wrapVertical);
			case Horizontal: moveLinear(values, index, direction.dx, allowWrap && wrapHorizontal);
			case Grid(columns): moveGrid(values, index, direction, columns, allowWrap);
		};
	}

	private function moveLinear(values:Array<MenuElementNode>, index:Int, delta:Int, wrap:Bool):Null<MenuElementNode>
	{
		if (delta == 0)
			return null;
		var next = index + delta;
		var checked = 0;
		while (checked++ < values.length)
		{
			if (next < 0 || next >= values.length)
			{
				if (!wrap)
					return null;
				next = next < 0 ? values.length - 1 : 0;
			}
			if (values[next].canFocus())
				return values[next];
			next += delta;
		}
		return null;
	}

	private function moveGrid(values:Array<MenuElementNode>, index:Int, direction:Direction, columns:Int, allowWrap:Bool):Null<MenuElementNode>
	{
		if (direction.dx != 0 && direction.dy == 0)
		{
			var rowStart = Std.int(index / columns) * columns;
			var rowEnd = M.min(rowStart + columns, values.length) - 1;
			var next = index + direction.dx;
			var checked = 0;
			while (checked++ <= rowEnd - rowStart)
			{
				if (next < rowStart || next > rowEnd)
				{
					if (!allowWrap || !wrapHorizontal)
						return null;
					next = next < rowStart ? rowEnd : rowStart;
				}
				if (values[next].canFocus())
					return values[next];
				next += direction.dx;
			}
			return null;
		}
		if (direction.dy == 0)
			return null;

		var rows = M.ceil(values.length / columns);
		var column = index % columns;
		var row = Std.int(index / columns) + direction.dy;
		var checked = 0;
		while (checked++ < rows)
		{
			if (row < 0 || row >= rows)
			{
				if (!allowWrap || !wrapVertical)
					return null;
				row = row < 0 ? rows - 1 : 0;
			}
			var start = row * columns;
			var end = M.min(start + columns, values.length) - 1;
			if (start <= end)
			{
				var candidate = M.min(start + column, end);
				if (values[candidate].canFocus())
					return values[candidate];
				for (distance in 1...columns)
				{
					var left = candidate - distance;
					var right = candidate + distance;
					if (left >= start && values[left].canFocus())
						return values[left];
					if (right <= end && values[right].canFocus())
						return values[right];
				}
			}
			row += direction.dy;
		}
		return null;
	}

	private function set_layout(value:MenuLayout):MenuLayout
		return layout = validateLayout(value);

	private static function validateLayout(value:MenuLayout):MenuLayout
	{
		if (value == null)
			throw 'Menu group layout cannot be null.';
		switch value
		{
			case Grid(columns) if (columns <= 0):
				throw 'Menu grid columns must be positive.';
			default:
		}
		return value;
	}

	private function validateLink(direction:Direction, group:MenuGroupNode)
	{
		if (group == null || group == this)
			throw 'Menu group links require another group.';
		if ((direction.dx == 0) == (direction.dy == 0))
			throw 'Menu group links require a cardinal direction.';
	}
}
