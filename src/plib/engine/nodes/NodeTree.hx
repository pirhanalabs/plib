package plib.engine.nodes;

import haxe.ds.ObjectMap;
import plib.engine.Application;
import plib.engine.nodes.Node.NodeState;
import plib.engine.nodes.Node.ProcessMode;

/** Permanent root created by `Application` and owned by one `NodeTree`. **/
class RootNode extends Node
{
	public function new()
		super();

	override function remove():Bool
	{
		throw 'The root node cannot be removed.';
		return false;
	}

	override function reparent(newParent:Node):Bool
	{
		throw 'The root node cannot be reparented.';
		return false;
	}

	override function destroy():Bool
	{
		throw 'The root node cannot be destroyed.';
		return false;
	}
}

private enum NodeCommand
{
	Add(parent:Node, child:Node);
	Remove(node:Node);
	Reparent(node:Node, newParent:Node);
	Destroy(node:Node);
}

private class NodeMutationQueue
{
	private final commands:Array<NodeCommand> = [];

	public function new() {}

	public function add(parent:Node, child:Node)
		commands.push(Add(parent, child));

	public function remove(node:Node)
		commands.push(Remove(node));

	public function reparent(node:Node, parent:Node)
		commands.push(Reparent(node, parent));

	public function destroy(node:Node)
		commands.push(Destroy(node));

	public function flush(apply:NodeCommand->Void, onError:(NodeCommand, Dynamic) -> Void)
	{
		if (commands.length == 0)
			return;
		var pending = commands.copy();
		commands.resize(0);
		var firstError:Dynamic = null;
		var failed = false;
		for (command in pending)
			try
				apply(command)
			catch (error)
			{
				if (!failed)
				{
					failed = true;
					firstError = error;
				}
				onError(command, error);
			}
		if (failed)
			throw firstError;
	}
}

private class NodeServiceRegistry
{
	private final values:ObjectMap<Dynamic, Node> = new ObjectMap();

	public function new() {}

	public function register<T:Node>(tree:NodeTree, key:ServiceKey<T>, node:T)
	{
		if (node.tree != tree || node.state != Active)
			throw 'Only active nodes can be registered as services.';
		if (values.get(key) == node)
			throw 'Service already registered: ${key.name}';
		values.set(key, node);
	}

	public function unregister<T:Node>(key:ServiceKey<T>, ?expected:T):Bool
	{
		var current = values.get(key);
		if (current == null || (expected != null && current != expected))
			return false;
		return values.remove(key);
	}

	public function get<T:Node>(key:ServiceKey<T>):T
		return cast values.get(key);

	public function require<T:Node>(key:ServiceKey<T>):T
	{
		var value = get(key);
		if (value == null)
			throw 'Required service is not registered: ${key.name}';
		return value;
	}

	public function unregisterNodes(nodes:Array<Node>)
	{
		var removed = new ObjectMap<Node, Bool>();
		for (node in nodes)
			removed.set(node, true);
		var keys:Array<Dynamic> = [];
		for (key => node in values)
			if (removed.exists(node))
				keys.push(key);
		for (key in keys)
			values.remove(key);
	}

	public function clear()
		values.clear();
}

private typedef TraversalItem =
{
	var node:Node;
	var depth:Int;
}

private class NodeTraversalEntry
{
	public final node:Node;
	public final depth:Int;
	public var subtreeEnd:Int = -1;

	public function new(node:Node, depth:Int)
	{
		this.node = node;
		this.depth = depth;
	}
}

private class NodeTraversalCache
{
	private final entries:Array<NodeTraversalEntry> = [];
	private var dirty:Bool = true;

	public function new() {}

	public function invalidate()
		dirty = true;

	public function isDirty():Bool
		return dirty;

	public function rebuild(root:Node)
	{
		entries.resize(0);
		var stack:Array<TraversalItem> = [{node: root, depth: 0}];
		var open:Array<Int> = [];
		while (stack.length > 0)
		{
			var item = stack.pop();
			while (open.length > 0)
			{
				var index = open[open.length - 1];
				if (entries[index].depth < item.depth)
					break;
				entries[index].subtreeEnd = entries.length;
				open.pop();
			}
			open.push(entries.length);
			entries.push(new NodeTraversalEntry(item.node, item.depth));
			var child = item.node.getChildCount() - 1;
			while (child >= 0)
				stack.push({node: item.node.getChild(child--), depth: item.depth + 1});
		}
		for (index in open)
			entries[index].subtreeEnd = entries.length;
		dirty = false;
	}

	public function run(tree:NodeTree, getMode:Node->ProcessMode, callback:Node->Void)
	{
		var index = 0;
		while (index < entries.length)
		{
			var entry = entries[index];
			var node = entry.node;
			if (node.tree != tree || node.state != Active || node.paused)
			{
				index = entry.subtreeEnd;
				continue;
			}
			switch getMode(node)
			{
				case SkipSubtree:
					index = entry.subtreeEnd;
					continue;
				case SkipSelf:
					index++;
					continue;
				case Enabled:
					callback(node);
			}
			if (node.tree != tree || node.state != Active || node.paused || getMode(node) == SkipSubtree)
				index = entry.subtreeEnd;
			else
				index++;
		}
	}
}

private typedef StoredQuery = NodeQuery<Node>;

/** Tree-private sparse index of live queries by scope. **/
@:noCompletion
@:access(plib.engine.nodes.NodeQuery)
private class NodeQueryRegistry
{
	private final byScope:ObjectMap<Node, Array<StoredQuery>> = new ObjectMap();
	private final dirty:ObjectMap<StoredQuery, Bool> = new ObjectMap();
	private final pending:Array<StoredQuery> = [];
	private final pendingCompaction:ObjectMap<StoredQuery, Bool> = new ObjectMap();
	private var dirtyCount:Int = 0;
	private var batching:Bool = false;

	public function new() {}

	public function register<T:Node>(tree:NodeTree, scope:Node, query:NodeQuery<T>):NodeQuery<T>
	{
		if (query == null)
			throw 'Cannot register a null NodeQuery.';
		if (scope == null || scope.tree != tree || scope.state != Active)
			throw 'NodeQuery scope must be active in the owning tree.';
		var stored:StoredQuery = cast query;
		query.bind(tree, scope);
		var scoped = byScope.get(scope);
		if (scoped == null)
		{
			scoped = [];
			byScope.set(scope, scoped);
		}
		scoped.push(stored);
		try
			query.rebuild()
		catch (error)
		{
			scoped.remove(stored);
			if (scoped.length == 0)
				byScope.remove(scope);
			query.rollbackRegistration();
			throw error;
		}
		return query;
	}

	public function invalidateAncestors(node:Null<Node>)
	{
		var current = node;
		while (current != null)
		{
			var scoped = byScope.get(current);
			if (scoped != null)
				for (query in scoped)
					if (!dirty.exists(query))
					{
						dirty.set(query, true);
						dirtyCount++;
					}
			current = current.parent;
		}
	}

	public function addSubtreeToAncestors(parent:Null<Node>, nodes:Array<Node>)
	{
		visitAncestors(parent, query -> query.addNodes(nodes));
	}

	public function removeSubtreeFromAncestors(parent:Null<Node>, nodes:Array<Node>)
	{
		visitAncestors(parent, query ->
		{
			if (!query.removeNodes(nodes))
				return;
			if (batching)
				pendingCompaction.set(query, true);
			else
				query.compactRemovedNodes();
		});
	}

	public function beginMutationBatch()
	{
		if (batching)
			throw 'Node query mutation batches cannot be nested.';
		batching = true;
	}

	public function endMutationBatch()
	{
		if (!batching)
			return;
		batching = false;
		for (query => _ in pendingCompaction)
			if (query.active)
				query.compactRemovedNodes();
		pendingCompaction.clear();
	}

	public function removeScopes(nodes:Array<Node>)
	{
		for (node in nodes)
		{
			var scoped = byScope.get(node);
			if (scoped == null)
				continue;
			for (query in scoped)
			{
				if (dirty.remove(query))
					dirtyCount--;
				pendingCompaction.remove(query);
				query.deactivate();
			}
			byScope.remove(node);
		}
	}

	public function rebuildDirty()
	{
		if (dirtyCount == 0)
			return;
		pending.resize(0);
		for (query => _ in dirty)
			pending.push(query);
		dirty.clear();
		dirtyCount = 0;
		var firstError:Dynamic = null;
		var failed = false;
		for (query in pending)
			if (query.active)
				try
					query.rebuild()
				catch (error)
				{
					if (!failed)
					{
						failed = true;
						firstError = error;
					}
				}
		if (failed)
			throw firstError;
	}

	private function visitAncestors(node:Null<Node>, callback:StoredQuery->Void)
	{
		var current = node;
		var firstError:Dynamic = null;
		var failed = false;
		while (current != null)
		{
			var scoped = byScope.get(current);
			if (scoped != null)
				for (query in scoped)
					try
						callback(query)
					catch (error)
					{
						if (!failed)
						{
							failed = true;
							firstError = error;
						}
					}
			current = current.parent;
		}
		if (failed)
			throw firstError;
	}
}

/** Owns, traverses, and safely mutates one hierarchy of nodes. **/
class NodeTree
{
	public final root:RootNode;
	public final visualRoot:Null<h2d.Object>;

	/** Owning application, absent for headless and standalone trees. **/
	public final application:Null<Application>;

	public var processing(default, null):Bool;

	/**
		Optional error notification.
		Errors still propagate after the tree has restored its internal state.
	**/
	public var onError:Null<(operation:String, error:Dynamic) -> Void>;

	private final mutations:NodeMutationQueue;
	private final traversal:NodeTraversalCache;
	private final services:NodeServiceRegistry;
	private final queries:NodeQueryRegistry;

	private final deferred:Array<Void->Void>;
	private var flushingDeferred:Bool;

	public function new(root:RootNode, ?visualRoot:h2d.Object, ?application:Application)
	{
		if (root == null)
			throw 'NodeTree requires a root node.';
		if (root.parent != null)
			throw 'Root node cannot already have a parent.';
		if (root.state == Destroyed)
			throw 'Root node cannot be used.';

		this.root = root;
		this.visualRoot = visualRoot;
		this.application = application;

		this.processing = false;
		this.flushingDeferred = false;

		this.mutations = new NodeMutationQueue();
		this.traversal = new NodeTraversalCache();
		this.services = new NodeServiceRegistry();
		this.queries = new NodeQueryRegistry();
		this.deferred = [];

		var initialSubtree = root.collectSubtree();
		for (node in initialSubtree)
		{
			if (node.tree != null)
				throw 'Initial root subtree contains a node that already belongs to a tree.';
			if (node.state != Detached)
				throw 'Initial root subtree contains a non-detached node.';
		}

		for (node in initialSubtree)
		{
			@:privateAccess node.tree = this;
			@:privateAccess node.state = Active;
		}
		refreshViewportMetrics(initialSubtree);

		for (node in initialSubtree)
			node.onAddedToTree();
	}

	/** Returns the owner or throws when this is a standalone/headless tree. **/
	public function requireApplication():Application
	{
		if (application == null)
			throw 'This NodeTree is not owned by an Application.';
		return application;
	}

	// ---- Structural API ----

	public function add<T:Node>(parent:T, child:T):T
	{
		validateAdd(parent, child);

		if (processing)
		{
			markSubtree(child, PendingAttach);
			mutations.add(parent, child);
		}
		else
		{
			applyAdd(parent, child);
			queries.rebuildDirty();
		}
		return child;
	}

	public function remove(node:Node):Bool
	{
		if (node == root)
			throw 'The root node cannot be removed.';
		if (node.tree != this || node.state != Active)
			return false;

		if (processing)
		{
			markSubtree(node, PendingRemoval);
			mutations.remove(node);
		}
		else
		{
			applyRemove(node);
			queries.rebuildDirty();
		}
		return true;
	}

	public function reparent(node:Node, newParent:Node):Bool
	{
		if (node == root)
			throw 'The root node cannot be reparented.';

		if (node.parent == newParent)
			return false;

		validateReparent(node, newParent);

		if (processing)
		{
			markSubtree(node, PendingMove);
			mutations.reparent(node, newParent);
		}
		else
		{
			applyReparent(node, newParent);
			queries.rebuildDirty();
		}

		return true;
	}

	public function destroy(node:Node):Bool
	{
		if (node == root)
			throw 'The root node cannot be destroyed.';

		if (node.tree != this || node.state != Active)
			return false;

		node.onDestroyRequested();

		if (processing)
		{
			markSubtree(node, PendingDestroy);
			mutations.destroy(node);
		}
		else
		{
			applyDestroy(node);
			queries.rebuildDirty();
		}

		return true;
	}

	// ---- Deferred Work ----

	/**
		Runs after the current process and structural-commit cycle.

		If the tree is idle, the callback runs immediately. Calls made while
		flushing are appended and processed without recursive invocation.
	**/
	public function defer(callback:Void->Void)
	{
		if (callback == null)
			return;

		deferred.push(callback);
		if (!processing && !flushingDeferred)
			flushDeferred();
	}

	private function flushDeferred()
	{
		if (flushingDeferred)
			return;

		flushingDeferred = true;

		var firstError:Dynamic = null;
		var hasError = false;
		var index = 0;

		while (index < deferred.length)
		{
			var callback = deferred[index++];

			try
			{
				callback();
			}
			catch (error)
			{
				if (!hasError)
				{
					firstError = error;
					hasError = true;
				}

				reportError('deferred-callback', error);
			}
		}

		deferred.resize(0);
		flushingDeferred = false;

		if (hasError)
		{
			throw firstError;
		}
	}

	// ---- Processing ----

	public function process(frame:Frame)
	{
		if (processing)
			throw 'NodeTree.process() cannot be called recursively.';

		if (traversal.isDirty())
			traversal.rebuild(root);

		processing = true;

		var processError:Dynamic = null;
		var hasProcessError:Bool = false;

		try
		{
			traversal.run(this, node -> node.preupdateMode, node -> node.preupdate());
			traversal.run(this, node -> node.updateMode, node -> node.update(frame));
			traversal.run(this, node -> node.postupdateMode, node -> node.postupdate());
		}
		catch (error)
		{
			hasProcessError = true;
			processError = error;
			reportError('process', error);
		}

		processing = false;

		var commitError:Dynamic = null;
		var hasCommitError:Bool = false;

		queries.beginMutationBatch();
		try
		{
			mutations.flush(applyCommand, (command, error) -> reportError('mutation', error));
		}
		catch (error)
		{
			hasCommitError = true;
			commitError = error;
		}
		queries.endMutationBatch();

		var queryError:Dynamic = null;
		var hasQueryError:Bool = false;
		try
		{
			queries.rebuildDirty();
		}
		catch (error)
		{
			hasQueryError = true;
			queryError = error;
			reportError('query-rebuild', error);
		}

		var deferredError:Dynamic = null;
		var hasDeferredError:Bool = false;

		try
		{
			flushDeferred();
		}
		catch (error)
		{
			hasDeferredError = true;
			deferredError = error;
		}

		if (hasProcessError)
			throw processError;
		if (hasCommitError)
			throw commitError;
		if (hasQueryError)
			throw queryError;
		if (hasDeferredError)
			throw deferredError;
	}

	private function applyCommand(command:NodeCommand)
	{
		switch (command)
		{
			case Add(parent, child):
				applyAdd(parent, child);

			case Remove(node):
				applyRemove(node);

			case Reparent(node, newParent):
				applyReparent(node, newParent);

			case Destroy(node):
				applyDestroy(node);
		}
	}

	private function reportError(operation:String, error:Dynamic)
	{
		if (onError != null)
		{
			onError(operation, error);
		}
	}

	// ---- Validation ----

	private function validateAdd(parent:Node, child:Node)
	{
		if (parent == null || child == null)
			throw 'Parent and child are required.';
		if (parent.tree != this || parent.state != Active)
			throw 'Parent must be active in this tree.';
		if (child == parent)
			throw 'A node cannot be its own child.';
		if (child.parent != null)
			throw 'Child already has a parent.';
		if (child.tree != null)
			throw 'Child already belongs to a NodeTree.';
		if (child.state != Detached)
			throw 'Only detached nodes can be added.';
		if (child.isAncestorOf(parent))
			throw 'Adding this node would create a hierarchy cycle.';

		for (node in child.collectSubtree())
		{
			if (node.tree != null)
				throw 'Added subtree contains an attached node.';
			if (node.state != Detached)
				throw 'Added subtree contains a non-detached node.';
		}
	}

	private function validateReparent(node:Node, newParent:Node)
	{
		if (node == null || newParent == null)
			throw 'Node and new parent are required.';
		if (node.tree != this || node.state != Active)
			throw 'Node must be active in this tree';
		if (newParent.tree != this || newParent.state != Active)
			throw 'New parent must be active in this tree.';
		if (node == newParent || node.isAncestorOf(newParent))
			throw 'Reparenting would create a cycle.';
	}

	// ---- Mutation implementation ----

	private function applyAdd(parent:Node, child:Node)
	{
		// The command may have been buffered, so validate the parts
		// that could have changed before committing.
		if (parent.tree != this || parent.state != Active)
		{
			restoreDetachedState(child);
			throw 'Pending add parent is no longer active.';
		}

		if (child.parent != null || child.tree != null)
		{
			restoreDetachedState(child);
			throw 'Pending child is no longer detached.';
		}

		@:privateAccess parent.children.push(child);
		@:privateAccess child.parent = parent;

		var subtree = child.collectSubtree();

		for (node in subtree)
		{
			@:privateAccess node.tree = this;
			@:privateAccess node.state = Active;
		}
		refreshViewportMetrics(subtree);

		traversal.invalidate();

		// the complete subtree is structurally valid before hooks execute.
		for (node in subtree)
			node.onAddedToTree();

		queries.addSubtreeToAncestors(parent, subtree);
	}

	private function applyRemove(node:Node)
	{
		if (node.tree != this)
			return;

		var subtree = node.collectSubtree();
		var oldParent = node.parent;
		queries.removeSubtreeFromAncestors(oldParent, subtree);

		if (oldParent != null)
			@:privateAccess oldParent.children.remove(node);

		// Removed hooks execute bottom-up while tree references remain valid.
		var index = subtree.length - 1;
		while (index >= 0)
			subtree[index--].onRemovedFromTree();

		queries.removeScopes(subtree);
		services.unregisterNodes(subtree);
		@:privateAccess node.parent = null;

		for (current in subtree)
		{
			@:privateAccess current.tree = null;
			@:privateAccess current.state = Detached;
			@:privateAccess current.viewportMetrics = null;
		}

		traversal.invalidate();
	}

	private function applyReparent(node:Node, newParent:Node)
	{
		// The command may have been buffered, so validate the parts
		// that could have changed before committing.
		if (node.tree != this || newParent.tree != this)
		{
			restoreActiveState(node);
			throw 'Pending reparent nodes are no longer in this tree.';
		}

		if (node == newParent || node.isAncestorOf(newParent))
		{
			restoreActiveState(node);
			throw 'Pending reparent would create a cycle.';
		}

		var oldParent = node.parent;

		if (oldParent == null)
		{
			restoreActiveState(node);
			throw 'Cannot reparent a node without a parent.';
		}

		queries.invalidateAncestors(oldParent);
		queries.invalidateAncestors(newParent);

		@:privateAccess oldParent.children.remove(node);
		@:privateAccess newParent.children.push(node);
		@:privateAccess node.parent = newParent;
		refreshViewportMetrics(node.collectSubtree());

		restoreActiveState(node);
		traversal.invalidate();
		node.onReparented(oldParent, newParent);
	}

	private function applyDestroy(node:Node)
	{
		if (node.tree != this)
			return;

		var subtree = node.collectSubtree();
		var oldParent = node.parent;
		queries.removeSubtreeFromAncestors(oldParent, subtree);

		if (oldParent != null)
			@:privateAccess oldParent.children.remove(node);

		services.unregisterNodes(subtree);
		queries.removeScopes(subtree);

		var index = subtree.length - 1;
		while (index >= 0)
		{
			var current = subtree[index--];

			current.onRemovedFromTree();
			@:privateAccess current.tree = null;
			@:privateAccess current.parent = null;
			@:privateAccess current.state = Destroyed;
			@:privateAccess current.viewportMetrics = null;

			current.onDestroyed();
			@:privateAccess current.children.resize(0);
		}

		traversal.invalidate();
	}

	/** Refreshes cached context for a preorder subtree after a structural change. **/
	private function refreshViewportMetrics(subtree:Array<Node>)
	{
		for (node in subtree)
		{
			var provided = @:privateAccess node.provideViewportMetrics();
			@:privateAccess node.viewportMetrics = provided != null ? provided : node.parent == null ? null : node.parent.viewportMetrics;
		}
	}

	/** Refreshes one active subtree after its presentation provider changes. **/
	@:allow(plib.engine.nodes.LayerNode)
	private function refreshViewportMetricsFor(root:Node)
	{
		if (root != null && root.tree == this)
			refreshViewportMetrics(root.collectSubtree());
	}

	/** Refreshes presentation context and resize callbacks for the active tree. **/
	public function resize()
	{
		if (processing)
		{
			defer(resize);
			return;
		}
		var subtree = root.collectSubtree();
		refreshViewportMetrics(subtree);
		for (node in subtree)
			if (node.tree == this && node.state == Active)
				node.onResize();
	}

	private function markSubtree(root:Node, state:NodeState)
	{
		for (node in root.collectSubtree())
			@:privateAccess node.state = state;
	}

	private inline function restoreDetachedState(root:Node)
	{
		markSubtree(root, Detached);
	}

	private inline function restoreActiveState(root:Node)
	{
		markSubtree(root, Active);
	}

	// ---- Services ----

	/** Registers a cached query over the complete tree. **/
	public function registerQuery<T:Node>(query:NodeQuery<T>):NodeQuery<T>
	{
		return queries.register(this, root, query);
	}

	/** Internal entry point used by `Node.registerQuery`. **/
	@:allow(plib.engine.nodes.Node)
	private function registerScopedQuery<T:Node>(scope:Node, query:NodeQuery<T>):NodeQuery<T>
	{
		return queries.register(this, scope, query);
	}

	/** Registers an active node under a typed service key. **/
	public function register<T:Node>(key:ServiceKey<T>, node:T)
	{
		services.register(this, key, node);
	}

	public function unregister<T:Node>(key:ServiceKey<T>, ?expected:T):Bool
	{
		return services.unregister(key, expected);
	}

	public function get<T:Node>(key:ServiceKey<T>):Null<T>
	{
		return services.get(key);
	}

	public function require<T:Node>(key:ServiceKey<T>):T
	{
		return services.require(key);
	}
}
