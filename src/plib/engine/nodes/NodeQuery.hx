package plib.engine.nodes;

import haxe.ds.ObjectMap;

/**
	A cached, deterministic preorder selection of nodes in one tree scope.

	Queries are single-registration objects owned by `NodeTree`. Their contents
	change only when the hierarchy changes; arbitrary predicate dependencies are
	not observed automatically.
**/
class NodeQuery<T:Node>
{
	/** Tree that owns this query, or null after its scope leaves the tree. **/
	public var tree(default, null):Null<NodeTree>;

	/** Inclusive subtree root searched by this query. **/
	public var scope(default, null):Null<Node>;

	/** Whether this query is registered and can receive structural updates. **/
	public var active(default, null):Bool;

	/** Changes whenever the cached result membership or ordering changes. **/
	public var revision(default, null):Int;

	private final predicate:Node->Bool;
	private final matches:Array<T>;
	private final membership:ObjectMap<Node, Bool>;
	private final traversalStack:Array<Node>;
	private final pendingMatches:Array<T>;
	private final orderingStack:Array<Node>;
	private var registered:Bool;

	/** Creates an unregistered query using `predicate` as its membership test. **/
	public function new(predicate:Node->Bool)
	{
		if (predicate == null)
			throw 'NodeQuery requires a predicate.';

		this.predicate = predicate;
		this.matches = [];
		this.membership = new ObjectMap();
		this.traversalStack = [];
		this.pendingMatches = [];
		this.orderingStack = [];
		this.tree = null;
		this.scope = null;
		this.active = false;
		this.revision = 0;
		this.registered = false;
	}

	/** Creates a type-safe query with an optional typed filter. **/
	public static function ofType<T:Node>(type:Class<T>, ?filter:T->Bool):NodeQuery<T>
	{
		if (type == null)
			throw 'NodeQuery.ofType requires a node type.';

		return new NodeQuery(node ->
		{
			if (!Std.isOfType(node, type))
				return false;
			var typed:T = cast node;
			return filter == null || filter(typed);
		});
	}

	/** Number of cached matches. **/
	public inline function count():Int
	{
		return matches.length;
	}

	/** Returns whether at least one node matches. **/
	public inline function any():Bool
	{
		return matches.length > 0;
	}

	/** Tests cached membership without traversing the hierarchy. **/
	public inline function contains(node:Node):Bool
	{
		return membership.exists(node);
	}

	/** Returns a cached match by deterministic preorder index. **/
	public inline function get(index:Int):T
	{
		return matches[index];
	}

	/** Returns the first cached match, or null when empty. **/
	public inline function first():Null<T>
	{
		return matches.length == 0 ? null : matches[0];
	}

	/** Iterates the read-only cached results in tree preorder. **/
	public inline function iterator():Iterator<T>
	{
		return matches.iterator();
	}

	/** Returns a mutable snapshot without exposing internal query storage. **/
	public function toArray():Array<T>
	{
		return matches.copy();
	}

	private function bind(tree:NodeTree, scope:Node)
	{
		if (registered)
			throw 'A NodeQuery can only be registered once.';

		this.tree = tree;
		this.scope = scope;
		this.active = true;
		this.registered = true;
	}

	private function rollbackRegistration()
	{
		clear();
		tree = null;
		scope = null;
		active = false;
		registered = false;
	}

	private function deactivate()
	{
		if (active)
			revision++;
		clear();
		tree = null;
		scope = null;
		active = false;
	}

	private function rebuild()
	{
		clear();
		if (!active || scope == null)
			return;

		traversalStack.push(scope);
		try
		{
			while (traversalStack.length > 0)
			{
				var node = traversalStack.pop();
				if (predicate(node))
				{
					matches.push(cast node);
					membership.set(node, true);
				}

				var childIndex = node.getChildCount() - 1;
				while (childIndex >= 0)
					traversalStack.push(node.getChild(childIndex--));
			}
		}
		catch (error)
		{
			clear();
			throw error;
		}

		revision++;
	}

	/** Adds matching nodes from one newly attached subtree. **/
	private function addNodes(nodes:Array<Node>)
	{
		if (!active)
			return;

		pendingMatches.resize(0);
		try
		{
			for (node in nodes)
			{
				if (!membership.exists(node) && predicate(node))
					pendingMatches.push(cast node);
			}
		}
		catch (error)
		{
			pendingMatches.resize(0);
			throw error;
		}

		if (pendingMatches.length == 0)
			return;

		var nextMatch = findNextMatchAfterSubtree(nodes[0].parent);
		var insertAt = nextMatch == null ? matches.length : matches.indexOf(cast nextMatch);
		if (insertAt < 0)
			insertAt = matches.length;

		var addedCount = pendingMatches.length;
		var oldLength = matches.length;
		matches.resize(oldLength + addedCount);
		var read = oldLength - 1;
		while (read >= insertAt)
		{
			matches[read + addedCount] = matches[read];
			read--;
		}

		for (offset in 0...addedCount)
		{
			var match = pendingMatches[offset];
			matches[insertAt + offset] = match;
			membership.set(match, true);
		}
		pendingMatches.resize(0);
		revision++;
	}

	/** Removes cached members contained in one departing subtree. **/
	private function removeNodes(nodes:Array<Node>):Bool
	{
		if (matches.length == 0 || nodes.length == 0)
			return false;

		var removedAny = false;
		for (node in nodes)
		{
			if (membership.remove(node))
				removedAny = true;
		}

		return removedAny;
	}

	/** Compacts cached results after one or more membership removals. **/
	private function compactRemovedNodes()
	{
		var write = 0;
		for (read in 0...matches.length)
		{
			var match = matches[read];
			if (membership.exists(match))
			{
				matches[write] = match;
				write++;
			}
		}
		matches.resize(write);
		revision++;
	}

	/** Finds the first cached match following a subtree in tree preorder. **/
	private function findNextMatchAfterSubtree(subtreeRoot:Null<Node>):Null<Node>
	{
		var current = subtreeRoot;
		while (current != null && current != scope)
		{
			var parent = current.parent;
			if (parent == null)
				return null;

			var foundCurrent = false;
			for (index in 0...parent.getChildCount())
			{
				var sibling = parent.getChild(index);
				if (!foundCurrent)
				{
					if (sibling == current)
						foundCurrent = true;
					continue;
				}

				var match = firstCachedMatchInSubtree(sibling);
				if (match != null)
					return match;
			}
			current = parent;
		}
		return null;
	}

	private function firstCachedMatchInSubtree(root:Node):Null<Node>
	{
		orderingStack.resize(0);
		orderingStack.push(root);
		while (orderingStack.length > 0)
		{
			var node = orderingStack.pop();
			if (membership.exists(node))
				return node;

			var childIndex = node.getChildCount() - 1;
			while (childIndex >= 0)
				orderingStack.push(node.getChild(childIndex--));
		}
		return null;
	}

	private function clear()
	{
		matches.resize(0);
		membership.clear();
		traversalStack.resize(0);
		pendingMatches.resize(0);
		orderingStack.resize(0);
	}
}

/** Incremental live consumer created directly from a `NodeQuery`. **/
class NodeQueryJob<T:Node>
{
	public final query:NodeQuery<T>;
	public final callback:T->Void;
	public var looping(default, null):Bool;
	public var completed(default, null):Bool = false;
	public var cancelled(default, null):Bool = false;
	public var processedCount(default, null):Int = 0;
	public var pass(default, null):Int = 0;

	private final processedThisPass:ObjectMap<Node, Bool> = new ObjectMap();
	private final processedThisStep:ObjectMap<Node, Bool> = new ObjectMap();
	private var observedRevision:Int;
	private var index:Int = 0;
	private var passHasWork:Bool = false;
	private var executing:Bool = false;

	public function new(query:NodeQuery<T>, callback:T->Void, looping:Bool = false)
	{
		if (query == null || callback == null)
			throw 'NodeQueryJob requires a query and callback.';
		this.query = query;
		this.callback = callback;
		this.looping = looping;
		observedRevision = query.revision;
	}

	/** Processes at most `maxItems` currently eligible query members. **/
	public function step(maxItems:Int):Int
	{
		if (maxItems < 0)
			throw 'NodeQueryJob item budget cannot be negative.';
		return execute(maxItems, null, false);
	}

	/** Processes members until the time budget expires and returns callback count. **/
	public function stepFor(maxSeconds:Float):Int
	{
		if (maxSeconds < 0)
			throw 'NodeQueryJob time budget cannot be negative.';
		return execute(0x3fffffff, haxe.Timer.stamp() + maxSeconds, false);
	}

	/** Immediately processes every member still eligible in this pass. **/
	public function complete():Int
		return execute(0x3fffffff, null, true);

	/** Finishes after the current pass instead of beginning another. **/
	public function stopLooping()
		looping = false;

	/** Enables repeated passes without visiting one node twice in the same pass. **/
	public function startLooping()
	{
		if (cancelled)
			return;
		looping = true;
		if (completed)
		{
			completed = false;
			processedThisPass.clear();
			index = 0;
			passHasWork = false;
			observedRevision = query.revision;
		}
	}

	/** Permanently stops this job without invoking remaining callbacks. **/
	public function cancel()
	{
		if (completed)
			return;
		cancelled = true;
		clearProgress();
	}

	/** Starts a fresh pass over the query's current membership. **/
	public function reset()
	{
		if (executing)
			throw 'NodeQueryJob cannot reset from inside its callback.';
		processedThisPass.clear();
		processedThisStep.clear();
		observedRevision = query.revision;
		index = 0;
		passHasWork = false;
		processedCount = 0;
		pass = 0;
		completed = false;
		cancelled = false;
	}

	/** Reports whether a non-looping pass completed or the job was cancelled. **/
	public function isFinished():Bool
		return completed || cancelled;

	private function execute(maxItems:Int, deadline:Null<Float>, stopAtPassEnd:Bool):Int
	{
		if (executing)
			throw 'NodeQueryJob cannot be stepped recursively.';
		if (maxItems == 0 || isFinished())
			return 0;
		if (!query.active)
		{
			cancelFromQuery();
			return 0;
		}
		processedThisStep.clear();
		executing = true;
		try
		{
			var result = run(maxItems, deadline, stopAtPassEnd);
			executing = false;
			processedThisStep.clear();
			return result;
		}
		catch (error)
		{
			executing = false;
			processedThisStep.clear();
			throw error;
		}
	}

	private function run(maxItems:Int, deadline:Null<Float>, stopAtPassEnd:Bool):Int
	{
		var count = 0;
		while (count < maxItems)
		{
			if (deadline != null && haxe.Timer.stamp() >= deadline)
				break;
			if (!query.active)
			{
				cancelFromQuery();
				break;
			}
			synchronize();
			if (index >= query.count())
			{
				if (!finishPass(stopAtPassEnd))
					break;
				continue;
			}
			var node = query.get(index++);
			if (processedThisPass.exists(node))
				continue;
			if (processedThisStep.exists(node))
			{
				index--;
				break;
			}
			processedThisPass.set(node, true);
			processedThisStep.set(node, true);
			passHasWork = true;
			processedCount++;
			count++;
			callback(node);
			if (cancelled)
				break;
		}
		return count;
	}

	private function finishPass(stopAtPassEnd:Bool):Bool
	{
		if (!passHasWork)
		{
			if (!looping)
				completed = true;
			return false;
		}
		pass++;
		processedThisPass.clear();
		passHasWork = false;
		index = 0;
		observedRevision = query.revision;
		if (!looping)
		{
			completed = true;
			return false;
		}
		return !stopAtPassEnd && query.count() > 0;
	}

	private function synchronize()
	{
		if (observedRevision != query.revision)
		{
			observedRevision = query.revision;
			index = 0;
		}
	}

	private function cancelFromQuery()
	{
		cancelled = true;
		clearProgress();
	}

	private function clearProgress()
	{
		processedThisPass.clear();
		processedThisStep.clear();
		index = 0;
		passHasWork = false;
	}
}
