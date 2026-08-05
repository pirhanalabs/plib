package plib.engine.nodes;

class NodeTree
{
	public final root:Node;

	public final visualRoot:h2d.Object;

	private final uniqueNodes:Map<String, Node>;
	private final cleanupCbs:Array<Void->Void>;

	var updating:Bool;

	public function new(root:Node, visualRoot:h2d.Object)
	{
		if (root.parent != null)
			throw 'The root node cannot already have a parent.';

		this.root = root;
		this.visualRoot = visualRoot;

		this.cleanupCbs = [];
		this.uniqueNodes = [];
		this.updating = false;

		attachSubtree(root);
	}

	// ---- cleanup callbacks ----
	public function addCleanupCb(fn:Void->Void)
	{
		if (!cleanupCbs.contains(fn))
			cleanupCbs.push(fn);
	}

	public function removeCleanupCb(fn:Void->Void)
	{
		cleanupCbs.remove(fn);
	}

	// ---- frame processing ----

	public function process(frame:Frame)
	{
		if (updating)
			throw 'NodeTree.process() cannot be called recursively.';

		updating = true;
		runPhase(frame, node -> !node.block_preupdate, node -> node.preupdate());
		runPhase(frame, node -> !node.block_update, node -> node.update(frame));
		runPhase(frame, node -> !node.block_postupdate, node -> node.postupdate());
		updating = false;

		for (cb in cleanupCbs.copy())
		{
			cb();
		}

		cleanup();
	}

	private function runPhase(frame:Frame, predicate:Node->Bool, cb:Node->Void)
	{
		var queue:Array<Node> = [root];

		var index = 0;

		while (index < queue.length)
		{
			var node = queue[index];

			if (node.destroyed || node.paused || !predicate(node))
				continue;

			cb(node);

			// check again in case state changed. If it has,
			// predicate only applies to children. This is a way to
			// block further operations on input, update or render.
			if (node.destroyed || node.paused || !predicate(node))
				continue;

			// Copying is not required here, but it gives predictable
			// behavior when children are added during an update.
			// New children begin processing on the next phase/frame instead
			// of unexpectedly appearing halfway through this traversal.
			var snapshot = node.children.copy();

			for (child in snapshot)
			{
				queue.push(child);
			}
		}
	}

	// ---- cleanup ----

	public function cleanup()
	{
		cleanupChildren(root);

		if (root.destroyed)
			throw 'The root node cannot be destroyed directly.';
	}

	private function cleanupChildren(parent:Node)
	{
		var index = parent.children.length - 1;

		while (index >= 0)
		{
			var child = parent.children[index];

			if (child.destroyed)
			{
				removeDestroyedSubtree(child);
				parent.children.splice(index, 1);
				@:privateAccess child.parent = null;
			}
			else
			{
				cleanupChildren(child);
			}

			index--;
		}
	}

	private function removeDestroyedSubtree(node:Node)
	{
		for (child in node.children.copy())
			removeDestroyedSubtree(child);

		node.onDestroyed();
		unregisterUnique(node);
		node.onRemovedFromTree();

		@:privateAccess node.tree = null;
		@:privateAccess node.parent = null;
		node.children.resize(0);
	}

	// ---- tree attachment ----

	public function validateSubtree(node:Node)
	{
		var pendingClasses:Map<String, Bool> = [];

		walkSubtree(node, current ->
		{
			if (!current.unique)
				return;

			var className = getNodeClassName(current);
			if (uniqueNodes.exists(className))
				throw 'Unique node class already exists: ${className}';

			if (pendingClasses.exists(className))
				throw 'Subtree contains multiple unique nodes of class: ${className}';

			pendingClasses.set(className, true);
		});
	}

	public function attachSubtree(node:Node)
	{
		validateSubtree(node);
		walkSubtree(node, current ->
		{
			@:privateAccess current.tree = this;
			registerUnique(current);
			current.onAddedToTree();
		});
	}

	public function detachSubtree(node:Node)
	{
		walkSubtreePostOrder(node, current ->
		{
			unregisterUnique(current);
			current.onRemovedFromTree();
			@:privateAccess current.tree = null;
		});
	}

	// ---- unique node access ----

	public function getUnique<T:Node>(c:Class<T>):Null<T>
	{
		var className = Type.getClassName(c);
		var node = uniqueNodes.get(className);
		return node == null ? null : cast node;
	}

	private function registerUnique(node:Node)
	{
		if (!node.unique)
			return;

		var className = getNodeClassName(node);
		if (uniqueNodes.exists(className))
			throw 'Unique node class already exists: ${className}';

		uniqueNodes.set(className, node);
	}

	private function unregisterUnique(node:Node)
	{
		if (!node.unique)
			return;

		var className = getNodeClassName(node);
		if (uniqueNodes.get(className) == node)
			uniqueNodes.remove(className);
	}

	// ---- traversal helpers ----
	public function walkSubtree(node:Node, cb:Node->Void)
	{
		var queue = [node];
		var index = 0;

		while (index < queue.length)
		{
			var current = queue[index];

			cb(current);
			for (child in current.children)
				queue.push(child);

			index++;
		}
	}

	public function visitSubtree(node:Node, cb:Node->Void)
	{
		cb(node);
		for (child in node.children)
			visitSubtree(child, cb);
	}

	public function walkSubtreePostOrder(node:Node, cb:Node->Void)
	{
		for (child in node.children)
			walkSubtreePostOrder(child, cb);
		cb(node);
	}

	private static function getNodeClassName(node:Node)
	{
		var nodeClass = Type.getClass(node);

		if (nodeClass == null)
			throw 'Node has no runtime class';

		return Type.getClassName(nodeClass);
	}
}

typedef TraversalEntry =
{
	node:Node,
	parentPaused:Bool,
}
