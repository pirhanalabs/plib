package plib.engine.nodes;

enum ScreenOperation
{
	Push(screen:ScreenNode);
	Pop;
	Replace(screen:ScreenNode);
	ClearAndPush(screen:ScreenNode);
	Clear;
}

class ScreenManager extends VisualNode
{
	public var current(get, never):Null<ScreenNode>;

	final screens:Array<ScreenNode>;
	final pending:plib.common.structs.Queue<ScreenOperation>;

	var applyingOperations:Bool;

	public function new()
	{
		super(new h2d.Object(), true);
		screens = [];
		pending = new plib.common.structs.Queue(64);
		applyingOperations = false;
	}

	override function onAddedToTree()
	{
		super.onAddedToTree();
		tree.addCleanupCb(applyPendingOperations);
	}

	override function onRemovedFromTree()
	{
		super.onRemovedFromTree();
		tree.removeCleanupCb(applyPendingOperations);
	}

	inline function get_current()
	{
		return screens.length == 0 ? null : screens[screens.length - 1];
	}

	// ---- public-facing operations ----

	public function push(screen:ScreenNode)
	{
		if (screen == null)
			throw 'Cannot push a null screen.';

		if (screen.parent != null || screen.tree != null)
			throw 'Screen is already attached to a node tree';

		pending.enqueue(Push(screen));
	}

	public function pop()
	{
		var screen = current;

		if (screen == null)
			return;

		screen.pause();
		pending.enqueue(Pop);
	}

	public function replace(screen:ScreenNode)
	{
		if (screen == null)
			throw 'Cannot replace with a null screen.';
		if (screen.parent != null || screen.tree != null)
			throw 'Screen is already attached to a node tree.';
		current.pause();
		pending.enqueue(Replace(screen));
	}

	public function change(screen:ScreenNode)
	{
		if (screen == null)
			throw 'Cannot change to a null screen.';
		if (screen.parent != null || screen.tree != null)
			throw 'Screen is already attached to a node tree.';
		pending.enqueue(ClearAndPush(screen));
	}

	public inline function hasScreens()
	{
		return screens.length > 0;
	}

	public function contains(screen:ScreenNode)
	{
		return screens.contains(screen);
	}

	// ---- applying transitions ----

	public function applyPendingOperations()
	{
		if (applyingOperations)
			throw 'Screen operations cannot be applied recursively.';

		applyingOperations = true;

		while (pending.any())
		{
			var operation = pending.dequeue();

			switch (operation)
			{
				case Push(screen):
					applyPush(screen);
				case Pop:
					applyPop();
				case Replace(screen):
					applyReplace(screen);
				case Clear:
					applyClear();
				case ClearAndPush(screen):
					applyClear();
					applyPush(screen);
			}
		}

		applyingOperations = false;
		refreshScreenStates();
	}

	function applyPush(screen:ScreenNode)
	{
		var previous = current;

		if (previous != null)
			previous.onCovered();

		screens.push(screen);
		addChild(screen);
		screen.onEnter();
	}

	function applyPop()
	{
		var screen = current;
		if (screen == null)
			return;

		screen.onExit();
		screens.pop();

		// Destruction remains deferred through the regular node cleanup.
		// The screen immediately stops participating in scene-manager updates.
		screen.destroy();

		var revealed = current;
		if (revealed != null)
			revealed.onRevealed();
	}

	function applyReplace(screen:ScreenNode)
	{
		var previous = current;
		if (previous != null)
		{
			previous.onExit();
			screens.pop();
			previous.destroy();
		}
		screens.push(screen);
		addChild(screen);
		screen.onEnter();
	}

	function applyClear()
	{
		while (screens.length > 0)
		{
			var screen = screens.pop();
			screen.onExit();
			screen.destroy();
		}
	}

	// ---- screen states ----

	private function refreshScreenStates()
	{
		refreshDisplayOrder();
	}

	private function refreshDisplayOrder()
	{
		for (index in 0...screens.length)
		{
			var screen = screens[index];

			// Move each display to its stack position.
			// h2d.Object.addChildAt() reparents the object when necessary.
			display.addChildAt(screen.display, index);
		}
	}

	override function onDestroyRequested()
	{
		pending.clear();
		applyClear();
	}
}
