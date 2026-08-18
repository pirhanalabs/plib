package plib.engine.nodes;

import plib.engine.Application;
import plib.engine.input.InputSystem;
import plib.engine.nodes.LayerNode.ViewportMetrics;

enum NodeState
{
	Detached;
	Active;
	PendingAttach;
	PendingMove;
	PendingRemoval;
	PendingDestroy;
	Destroyed;
}

enum abstract ProcessMode(Int)
{
	var Enabled = 0;
	var SkipSelf = 1;
	var SkipSubtree = 2;
}

/** Hierarchical, non-visual game object with three frame lifecycle phases. **/
class Node
{
	public var parent(default, null):Null<Node>;
	public var tree(default, null):Null<NodeTree>;
	public var state(default, null):NodeState;

	/** Cached metrics inherited from the closest presentation-space ancestor. **/
	public var viewportMetrics(default, null):Null<ViewportMetrics>;

	public var paused(default, null):Bool;
	public var preupdateMode:ProcessMode;
	public var updateMode:ProcessMode;
	public var postupdateMode:ProcessMode;

	@:allow(plib.engine.nodes.NodeTree)
	private final children:Array<Node>;

	/** Creates a detached, reusable node; attach it with `parent.add(node)`. **/
	public function new()
	{
		parent = null;
		tree = null;
		state = Detached;
		viewportMetrics = null;
		paused = false;

		preupdateMode = Enabled;
		updateMode = Enabled;
		postupdateMode = Enabled;

		children = [];
	}

	// ---- Hierarchy Access ----

	/** Returns the number of direct logical children. **/
	public inline function getChildCount():Int
	{
		return children.length;
	}

	/** Returns the direct child at `index`, throwing when out of range. **/
	public inline function getChild(index:Int):Node
	{
		return children[index];
	}

	/** Does not expose the mutable children array. **/
	public inline function childIterator():Iterator<Node>
	{
		return children.iterator();
	}

	/** Walks parents and returns this hierarchy's topmost node. **/
	public function getRoot():Node
	{
		var current:Node = this;
		while (current.parent != null)
			current = current.parent;
		return current;
	}

	/** Owning application. Detached and headless-tree nodes cannot access it. **/
	public var app(get, never):Application;

	private function get_app():Application
	{
		if (tree == null)
			throw 'Detached nodes cannot access the application.';
		return tree.requireApplication();
	}

	/** Resolves the application-owned input system. **/
	public var input(get, never):InputSystem;

	private function get_input():InputSystem
	{
		return app.inputs;
	}

	/** Returns inherited metrics or throws outside a presentation coordinate space. **/
	public function requireViewportMetrics():ViewportMetrics
	{
		if (viewportMetrics == null)
			throw 'Node is not inside a viewport coordinate space.';
		return viewportMetrics;
	}

	/** Override on nodes that establish a presentation coordinate space. **/
	@:allow(plib.engine.nodes.NodeTree)
	private function provideViewportMetrics():Null<ViewportMetrics>
	{
		return null;
	}

	/** Called after resize handling refreshes this node's inherited metrics. **/
	public function onResize() {}

	/** Returns whether this node is an ancestor of `node`. **/
	public function isAncestorOf(node:Node):Bool
	{
		var current:Node = node.parent;
		while (current != null)
		{
			if (current == this)
				return true;
			current = current.parent;
		}
		return false;
	}

	/** Returns whether this node is a descendant of `node`. **/
	public inline function isDescendantOf(node:Node):Bool
	{
		return node.isAncestorOf(this);
	}

	// ---- Structural Operations ----

	/**
		Add a child node to this node.

		The child should not be owned by a tree or an
		error will be thrown.
	**/
	public function add<T:Node>(child:T):T
	{
		validateReusable();

		if (child == null)
			throw 'Cannot add a null child.';

		if (tree != null)
		{
			tree.add(this, child);
		}
		else
		{
			addDetached(child);
		}

		return child;
	}

	/**
		Registers a cached query scoped to this node's inclusive subtree.
		The owning tree deactivates it automatically when this scope leaves.
	**/
	public function registerQuery<T:Node>(query:NodeQuery<T>):NodeQuery<T>
	{
		if (tree == null || state != Active)
			throw 'Only active nodes can register queries.';
		return tree.registerScopedQuery(this, query);
	}

	private function addDetached<T:Node>(child:T)
	{
		if (child == this)
			throw 'A node cannot be its own child.';
		if (child.state == Destroyed)
			throw 'A destroyed node cannot be attached.';
		if (child.state != Detached)
			throw 'Only detached nodes can be attached to detached parents.';
		if (child.parent != null)
			throw 'Node already has a parent.';
		if (child.isAncestorOf(this))
			throw 'Adding this node would create a hierarchy cycle.';

		children.push(child);
		child.parent = this;
	}

	/** Detaches this reusable subtree now or after the active tree pass. **/
	public function remove():Bool
	{
		if (tree != null)
			return tree.remove(this);

		if (parent == null)
			return false;

		parent.children.remove(this);
		parent = null;
		return true;
	}

	/** Moves this subtree under `newParent` while preserving the node instances. **/
	public function reparent(newParent:Node):Bool
	{
		validateReusable();

		if (newParent == null)
			throw 'A node cannot be reparented to null';
		if (newParent == this || isAncestorOf(newParent))
			throw 'Reparenting would create a hierarchy cycle.';

		if (tree != null)
			return tree.reparent(this, newParent);

		if (newParent.tree != null)
			throw 'Use the target NodeTree to attach this node.';

		if (parent != null)
			parent.children.remove(this);

		newParent.addDetached(this);
		return true;
	}

	/** Permanently removes this subtree and invokes destruction hooks once. **/
	public function destroy():Bool
	{
		if (state == Destroyed || state == PendingDestroy)
			return false;

		if (tree == null)
		{
			destroyDetached();
			return true;
		}

		return tree.destroy(this);
	}

	/** Permanently destroys a node that is not attached to a tree. **/
	public function destroyDetached()
	{
		if (parent != null)
			parent.children.remove(this);

		onDestroyRequested();

		var nodes = collectSubtree();
		var index = nodes.length - 1;

		while (index >= 0)
		{
			var node = nodes[index--];

			node.state = Destroyed;
			node.parent = null;
			node.tree = null;

			node.onDestroyed();
			node.children.resize(0);
		}
	}

	private function validateReusable()
	{
		if (state == Destroyed)
			throw 'Destroyed nodes cannot be reused.';

		switch (state)
		{
			case PendingAttach, PendingMove, PendingRemoval, PendingDestroy:
				throw 'Node already has a pending structural operation.';
			default:
		}
	}

	@:allow(plib.engine.nodes.NodeTree)
	private function collectSubtree():Array<Node>
	{
		var result:Array<Node> = [];
		var stack:Array<Node> = [this];

		while (stack.length > 0)
		{
			var node = stack.pop();
			result.push(node);

			var index = node.children.length - 1;
			while (index >= 0)
				stack.push(node.children[index--]);
		}

		return result;
	}

	// ---- pause ----

	/** Pauses this node; descendants inherit the pause through process modes. **/
	public inline function pause()
	{
		paused = true;
	}

	/** Clears this node's local paused flag. **/
	public inline function resume()
	{
		paused = false;
	}

	/** Reports whether this node or any ancestor is paused. **/
	public inline function isPausedInTree():Bool
	{
		var current:Null<Node> = this;
		while (current != null)
		{
			if (current.paused)
				return true;
			current = current.parent;
		}
		return false;
	}

	// ---- queries ----

	/** Performs a one-off depth-first search; prefer a registered query for repeated access. **/
	public function findFirst(predicate:Node->Bool, includeSelf:Bool = false):Null<Node>
	{
		if (includeSelf && predicate(this))
			return this;

		var queue:Array<Node> = [];
		var index:Int = 0;

		for (child in children)
			queue.push(child);

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

	/** Finds the first descendant of `type`, optionally testing this node first. **/
	public function findFirstOf<T:Node>(type:Class<T>, includeSelf:Bool = false):Null<T>
	{
		var result = findFirst(node -> Std.isOfType(node, type), includeSelf);
		return result == null ? null : cast result;
	}

	/** Returns a new array of matching subtree nodes; use registered queries when repeated. **/
	public function findAll(predicate:Node->Bool, includeSelf:Bool = false):Array<Node>
	{
		var result:Array<Node> = [];
		var queue:Array<Node> = [];
		var index = 0;

		if (includeSelf && predicate(this))
			result.push(this);

		for (child in children)
			queue.push(child);

		while (index < queue.length)
		{
			var node = queue[index++];

			if (predicate(node))
				result.push(node);

			for (child in node.children)
				queue.push(child);
		}

		return result;
	}

	/** Returns all subtree nodes assignable to `type`. **/
	public function findAllOf<T:Node>(type:Class<T>, includeSelf:Bool = false):Array<T>
	{
		var nodes = findAll(node -> Std.isOfType(node, type), includeSelf);
		return [for (node in nodes) cast node];
	}

	// ---- frame lifecycle ----

	/** Override for input/logic preparation before the main update pass. **/
	public function preupdate() {}

	/** Override for time-based game logic; structural edits are safely queued. **/
	public function update(frame:Frame) {}

	/** Override to commit visual state after logic has updated. **/
	public function postupdate() {}

	// ---- tree lifecycle ----

	/** Called after the complete subtree has valid parent and tree references. **/
	public function onAddedToTree() {}

	/** Called while tree references remain valid, immediately before detachment. **/
	public function onRemovedFromTree() {}

	/** Called immediately when destruction is requested. **/
	public function onDestroyRequested() {}

	/** Called during final destruction after onRemovedFromTree(). **/
	public function onDestroyed() {}

	/** Called after a same-tree reparent operation has been commited. **/
	public function onReparented(oldParent:Node, newParent:Node) {}
}
