package core.navigation;

class NavigationManager
{
	public var current(default, null):Null<INavigationInstance>;
	public var interactionsDisabled(default, null):Bool;
	public var groupManager:Null<NavigationGroupManager>;

	@:allow(core.navigation.NavigationGroupManager)
	private var instances:Map<INavigationInstance, NavigationNode>;

	/**
		Manages the navigation between interconnected INavigationInstance instances.
	**/
	public function new()
	{
		instances = new Map<INavigationInstance, NavigationNode>();
		current = null;
		interactionsDisabled = false;
	}

	public function execute()
	{
		if (current == null || interactionsDisabled)
			return;

		current.execute();
	}

	/**
		Adds an instance to the navigation manager.
	**/
	public function add(instance:INavigationInstance)
	{
		// todo: validate if instance already exists
		var node = new NavigationNode(instance);
		instance.navigation = this;
		instances.set(instance, node);
		return node;
	}

	private function getOrCreate(instance:INavigationInstance)
	{
		if (!instances.exists(instance))
		{
			add(instance);
		}
		return instances.get(instance);
	}

	/**
		Link the first instance to the second one, in the given direction.
	**/
	public function link(instance1:INavigationInstance, instance2:INavigationInstance, direction:engine.Direction)
	{
		var node1 = getOrCreate(instance1);
		var node2 = getOrCreate(instance2);
		node1.link(node2, direction);
	}

	public function link2(instance1:INavigationInstance, instance2:INavigationInstance, direction:engine.Direction)
	{
		link(instance1, instance2, direction);
		link(instance2, instance1, direction.getReverse());
	}

	public function clearLinks()
	{
		for (inst => node in instances)
		{
			node.clearLinks();
		}
	}

	/**
		Move from the current selected instance in a given direction, if possible.
	**/
	public function tryMove(direction:engine.Direction)
	{
		if (current == null || interactionsDisabled)
			return false;

		var node = instances.get(current);
		if (node == null)
			return false;

		var linked = node.getLink(direction);

		if (linked == null)
			return false;

		changeCurrent(current, linked.instance);
		linked.previous.set(direction, node);
		return true;
	}

	/**
		Selects the new current active instance.
	**/
	public function select(instance:INavigationInstance)
	{
		var node = instances.get(instance);

		if (node == null)
			return false;

		if (groupManager != null)
		{
			groupManager.setCurrentGroup(this);
		}

		changeCurrent(current, instance);
		return true;
	}

	/**
		Changes the current active instance.
	**/
	private function changeCurrent(from:INavigationInstance, to:INavigationInstance)
	{
		if (from != null)
		{
			current = null;
			from.unfocus();
		}

		if (to != null)
		{
			current = to;
			to.focus();

			if (groupManager != null)
			{
				groupManager.notifyFocused(this, to);
			}
		}

		onCurrentChanged();
	}

	public function disableInteractions()
	{
		interactionsDisabled = true;
		for (k => v in instances)
		{
			k.disableInteractive();
		}
	}

	public function enableInteractions()
	{
		interactionsDisabled = false;
		for (k => v in instances)
		{
			k.enableInteractive();
		}
	}

	/** Dynamic callback to override. **/
	public dynamic function onCurrentChanged() {}
}
