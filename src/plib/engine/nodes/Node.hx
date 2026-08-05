package plib.engine.nodes;

class Node
{
	public var parent(default, null):Null<Node>;
	public var children(default, null):Array<Node>;

	public var tree(default, null):Null<NodeTree>;

	public var destroyed(default, null):Bool = false;
	public var paused(default, null):Bool = false;

	public var block_preupdate:Bool;
	public var block_update:Bool;
	public var block_postupdate:Bool;

	public final unique:Bool;

	public function new(unique:Bool = false)
	{
		this.unique = unique;
		this.parent = null;
		this.children = [];
		this.tree = null;

		this.block_preupdate = false;
		this.block_update = false;
		this.block_postupdate = false;
	}

	// ---- hierarchy ----

	public function addChild(node:Node)
	{
		if (node == this)
			throw 'A node cannot be its own child.';
		if (node.parent != null)
			throw 'Node already has a parent.';
		if (isAncestorOf(node))
			throw 'Adding this node would create a hierarchy cycle.';

		// validate uniqueness
		if (tree != null)
			tree.validateSubtree(node);

		children.push(node);
		node.parent = this;

		if (tree != null)
			tree.attachSubtree(node);

		return node;
	}

	public function removeChild(node:Node)
	{
		if (node.parent != this)
			return false;

		if (tree != null)
			tree.detachSubtree(node);

		children.remove(node);
		node.parent = null;

		return true;
	}

	public function reparent(stepfather:Node)
	{
		if (parent == stepfather)
			return;

		if (stepfather == this || isDescendantOf(stepfather))
			throw 'Cannot reparent a node beneath itself';

		if (tree != stepfather.tree)
			throw "Use removeChild/addChild to move between NodeTrees.";

		if (parent != null)
			parent.removeChild(this);

		stepfather.addChild(this);
	}

	public function remove()
	{
		if (parent != null)
		{
			parent.removeChild(this);
		}
	}

	public function getRoot()
	{
		var node:Node = this;

		while (node.parent != null)
			node = node.parent;

		return node;
	}

	public function isAncestorOf(node:Node)
	{
		var c = node.parent;

		while (c != null)
		{
			if (c == this)
				return true;
			c = c.parent;
		}
		return false;
	}

	public function isDescendantOf(node:Node)
	{
		return node.isAncestorOf(this);
	}

	// ---- lifecycle state ----

	public function destroy()
	{
		if (destroyed)
			return;

		destroyed = true;
		onDestroyRequested();
	}

	/**
		Like pause, but triggers the onHide callback
		on every children. This is intended as a generic
		helper when we want something to happen to all children
		when pausing.
	**/
	public final function hide()
	{
		pause();

		if (tree != null)
		{
			tree.walkSubtree(this, (node) ->
			{
				node.onHide();
			});
		}
	}

	/**
		Like resume, but triggers the onShow callback
		on every children. This is intended as a generic
		helper when we want something to happen to all children
		when resuming.
	**/
	public final function show()
	{
		resume();

		if (tree != null)
		{
			tree.walkSubtree(this, (node) ->
			{
				node.onShow();
			});
		}
	}

	private function onHide() {}

	private function onShow() {}

	public inline function pause()
	{
		paused = true;
	}

	public inline function resume()
	{
		paused = false;
	}

	public function isPausedInTree()
	{
		var node:Null<Node> = this;

		while (node != null)
		{
			if (node.paused)
				return true;
			node = node.parent;
		}

		return false;
	}

	// ---- searching ----

	public function findFirstOf<T:Node>(c:Class<T>, includeSelf:Bool = false):T
	{
		var node = findFirst(n -> Std.isOfType(n, c), includeSelf);
		return node == null ? null : cast node;
	}

	public function findAllOf<T:Node>(c:Class<T>, includeSelf:Bool = false):Array<T>
	{
		return findAll(n -> Std.isOfType(n, c), includeSelf);
	}

	public function findFirst(predicate:Node->Bool, includeSelf:Bool = false):Null<Node>
	{
		if (includeSelf && predicate(this))
			return cast this;

		var queue = children.copy();
		var index = 0;

		while (index < queue.length)
		{
			var node = queue[index++];

			if (predicate(node))
				return node;

			for (child in node.children)
				queue.push(child);
		}

		return null;
	}

	public function findAll<T:Node>(predicate:Node->Bool, includeSelf:Bool = false):Array<T>
	{
		var results:Array<T> = [];

		if (includeSelf && predicate(this))
			results.push(cast this);

		var queue = children.copy();
		var index = 0;

		while (index < queue.length)
		{
			var node = queue[index++];

			if (predicate(node))
				results.push(cast node);

			for (child in node.children)
				queue.push(child);
		}

		return results;
	}

	// ---- frame lifecycle ----

	public function preupdate():Void {}

	public function update(frame:Frame):Void {}

	public function postupdate():Void {}

	// ---- tree lifecycle hooks ----

	public function onAddedToTree():Void {}

	public function onRemovedFromTree():Void {}

	public function onDestroyRequested():Void {}

	public function onDestroyed():Void {}
}
