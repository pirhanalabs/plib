package plib.engine.nodes;

import haxe.ds.ObjectMap;

private enum ScreenOperation
{
	Push(screen:ScreenNode);
	Pop;
	Replace(screen:ScreenNode);
	Change(screen:ScreenNode);
	Clear;
}

/** Owns a screen stack and serializes reentrant screen operations. **/
class ScreenManager extends Node
{
	private final screens:Array<ScreenNode>;
	private final operations:Array<ScreenOperation>;

	private var operationScheduled:Bool;
	private var applyingOperations:Bool;
	private final blockedManagers:Array<ScreenManager>;
	private final blockingManagers:Array<ScreenManager>;
	private final activeBlockers:ObjectMap<ScreenManager, Bool>;

	/** Creates an empty screen stack; normally mount it under a presentation layer. **/
	public function new()
	{
		super();
		screens = [];
		operations = [];

		operationScheduled = false;
		applyingOperations = false;
		blockedManagers = [];
		blockingManagers = [];
		activeBlockers = new ObjectMap();
	}

	// ---- Manager relationships ----

	/** Makes this manager cover `target` whenever this stack is non-empty. **/
	public function blocks(target:ScreenManager):ScreenManager
	{
		if (target == null || target == this)
			throw 'A screen manager can only block another manager.';
		if (blockedManagers.contains(target))
			return this;
		if (tree != null && target.tree != null && tree != target.tree)
			throw 'Linked screen managers must belong to the same NodeTree.';
		if (target.blocksTransitively(this))
			throw 'Screen manager blocking relationships cannot contain cycles.';
		blockedManagers.push(target);
		target.blockingManagers.push(this);
		if (!isEmpty() && (tree == null || target.tree == null || tree == target.tree))
			target.addActiveBlocker(this);
		return this;
	}

	/** Removes a relationship previously created with `blocks()`. **/
	public function unblocks(target:ScreenManager):Bool
	{
		if (target == null || !blockedManagers.remove(target))
			return false;
		target.blockingManagers.remove(this);
		target.removeActiveBlocker(this);
		return true;
	}

	public inline function isExternallyBlocked():Bool
		return activeBlockers.iterator().hasNext();

	private function blocksTransitively(target:ScreenManager):Bool
	{
		if (this == target)
			return true;
		var pending = blockedManagers.copy();
		var visited:ObjectMap<ScreenManager, Bool> = new ObjectMap();
		while (pending.length > 0)
		{
			var current = pending.pop();
			if (current == target)
				return true;
			if (visited.exists(current))
				continue;
			visited.set(current, true);
			for (next in current.blockedManagers)
				pending.push(next);
		}
		return false;
	}

	private function addActiveBlocker(source:ScreenManager)
	{
		if (activeBlockers.exists(source))
			return;
		var wasBlocked = isExternallyBlocked();
		activeBlockers.set(source, true);
		if (!wasBlocked)
		{
			var screen = top();
			if (screen != null)
				screen.coverScreen();
		}
	}

	private function removeActiveBlocker(source:ScreenManager)
	{
		if (!activeBlockers.remove(source) || isExternallyBlocked())
			return;
		var screen = top();
		if (screen != null)
			screen.revealScreen();
	}

	private function activateBlocking()
	{
		for (target in blockedManagers)
			target.addActiveBlocker(this);
	}

	private function deactivateBlocking()
	{
		for (target in blockedManagers)
			target.removeActiveBlocker(this);
	}

	// ---- Stack access ----

	/** Returns the number of managed screens. **/
	public inline function getCount()
	{
		return screens.length;
	}

	/** Reports whether the stack contains no screens. **/
	public inline function isEmpty()
	{
		return screens.length == 0;
	}

	/** Returns the active top screen, or `null` when empty. **/
	public inline function top()
	{
		return screens.length == 0 ? null : screens[screens.length - 1];
	}

	/** Returns a screen by bottom-to-top stack index. **/
	public inline function getScreen(index:Int)
	{
		if (index < 0 || index >= screens.length)
			return null;

		return screens[index];
	}

	/** Reports whether this manager owns `screen`. **/
	public function contains(screen:ScreenNode)
	{
		return screens.contains(screen);
	}

	/** Returns a screen's stack index or `-1`. **/
	public function indexOf(screen:ScreenNode)
	{
		return screens.indexOf(screen);
	}

	// ---- Public operations ----

	/** Adds and enters a new top screen, suspending the previous top as configured. **/
	public function push<T:ScreenNode>(screen:T):T
	{
		validateNewScreen(screen);
		enqueue(Push(screen));
		return screen;
	}

	/** Exits and removes the top screen, returning it when present. **/
	public function pop()
	{
		enqueue(Pop);
	}

	/** Replaces the top screen with `screen`, or pushes when empty. **/
	public function replace<T:ScreenNode>(screen:T):T
	{
		validateNewScreen(screen);
		enqueue(Replace(screen));
		return screen;
	}

	/** Removes every screen, then pushes the new screen. **/
	public function change<T:ScreenNode>(screen:T):T
	{
		validateNewScreen(screen);
		enqueue(Change(screen));
		return screen;
	}

	/** Exits and removes every managed screen. **/
	public function clear()
	{
		enqueue(Clear);
	}

	private function validateNewScreen(screen:ScreenNode)
	{
		if (screen == null)
			throw 'Screen cannot be null.';
		if (screen.state == Destroyed)
			throw 'Destroyed Screens cannot be used.';
		if (screen.manager != null)
			throw 'Screen already belongs to a ScreenManager.';
		if (screen.parent != null || screen.tree != null)
			throw 'Screen is already attached to a node hierarchy.';
	}

	// ---- Operation Queue ----

	private function enqueue(operation:ScreenOperation)
	{
		operations.push(operation);

		// Operations created by lifecycle callbacks are consumed by the
		// current drain loop.
		if (applyingOperations || operationScheduled)
			return;

		operationScheduled = true;

		if (tree == null)
		{
			// Allow a detached manager to build its initial screen stack.
			drainOperations();
		}
		else
		{
			tree.defer(drainOperations);
		}
	}

	private function drainOperations()
	{
		if (applyingOperations)
			return;

		applyingOperations = true;
		operationScheduled = false;

		var firstError:Dynamic = null;
		var hasError:Bool = false;
		var index = 0;

		while (index < operations.length)
		{
			var operation = operations[index++];

			try
			{
				switch (operation)
				{
					case Push(screen):
						applyPush(screen);

					case Pop:
						applyPop();

					case Replace(screen):
						applyReplace(screen);

					case Change(screen):
						applyChange(screen);

					case Clear:
						applyClear();
				}
			}
			catch (error)
			{
				if (!hasError)
				{
					hasError = true;
					firstError = error;
				}
			}
		}

		operations.resize(0);
		applyingOperations = false;

		if (hasError)
			throw firstError;
	}

	// ---- Operation Implementation ----

	private function applyPush(screen:ScreenNode)
	{
		validateNewScreen(screen);

		var previous = top();
		var activatesBlocking = previous == null;
		if (activatesBlocking)
			activateBlocking();

		if (previous != null)
			previous.coverScreen();

		screen.attachToManager(this);

		try
		{
			add(screen);
			screens.push(screen);
			screen.enterScreen();
			if (isExternallyBlocked())
				screen.coverScreen();
		}
		catch (error)
		{
			// restore the logical ownership if structural attachment failed.
			@:privateAccess screen.manager = null;

			if (previous != null && !isExternallyBlocked())
				previous.revealScreen();
			if (activatesBlocking)
				deactivateBlocking();

			throw error;
		}
	}

	private function applyPop()
	{
		var screen = top();

		if (screen == null)
			return null;

		screen.exitScreen();
		screens.pop();

		// The manager owns stack screens, so popping destroys them.
		screen.destroy();

		var revealed = top();

		if (revealed != null && !isExternallyBlocked())
			revealed.revealScreen();
		if (screens.length == 0)
			deactivateBlocking();

		return screen;
	}

	private function applyReplace(screen:ScreenNode)
	{
		validateNewScreen(screen);

		var previous = top();
		if (previous == null)
			activateBlocking();

		if (previous != null)
		{
			previous.exitScreen();
			screens.pop();
			previous.destroy();
		}

		screen.attachToManager(this);
		add(screen);
		screens.push(screen);
		screen.enterScreen();
		if (isExternallyBlocked())
			screen.coverScreen();
	}

	private function applyChange(screen:ScreenNode)
	{
		validateNewScreen(screen);
		var wasEmpty = screens.length == 0;
		if (wasEmpty)
			activateBlocking();

		// Clear without revealing intermediate screens.
		while (screens.length > 0)
		{
			var current = screens.pop();
			current.exitScreen();
			current.destroy();
		}

		screen.attachToManager(this);
		add(screen);
		screens.push(screen);
		screen.enterScreen();
		if (isExternallyBlocked())
			screen.coverScreen();
	}

	private function applyClear()
	{
		var wasNonEmpty = screens.length > 0;
		while (screens.length > 0)
		{
			var screen = screens.pop();
			screen.exitScreen();
			screen.destroy();
		}
		if (wasNonEmpty)
			deactivateBlocking();
	}

	// ---- Manager Lifecycle ----

	override function onAddedToTree()
	{
		super.onAddedToTree();
		for (target in blockedManagers)
		{
			if (target.tree != null && target.tree != tree)
				throw 'Linked screen managers must belong to the same NodeTree.';
			if (!isEmpty() && target.tree == tree)
				target.addActiveBlocker(this);
		}
		for (source in blockingManagers)
		{
			if (source.tree != null && source.tree != tree)
				throw 'Linked screen managers must belong to the same NodeTree.';
			if (!source.isEmpty() && source.tree == tree)
				addActiveBlocker(source);
		}
	}

	override function onRemovedFromTree()
	{
		deactivateBlocking();
		for (source in blockingManagers)
			removeActiveBlocker(source);
		super.onRemovedFromTree();
	}

	override function onDestroyRequested()
	{
		deactivateBlocking();
		for (target in blockedManagers.copy())
			unblocks(target);
		for (source in blockingManagers.copy())
			source.unblocks(this);
		activeBlockers.clear();
		// this normally runs during tree processing, so child destruction
		// requests are safely buffered by NodeTree.
		while (screens.length > 0)
		{
			var screen = screens.pop();

			if (!screen.exiting)
			{
				screen.exitScreen();
			}

			if (screen.state != Destroyed && screen.state != PendingDestroy)
			{
				screen.destroy();
			}
		}

		operations.resize(0);
		operationScheduled = false;

		super.onDestroyRequested();
	}
}
