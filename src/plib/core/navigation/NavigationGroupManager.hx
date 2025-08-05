package core.navigation;

typedef PortalTarget =
{
	targetGroup:NavigationManager,
	targetNode:INavigationInstance,
}

class NavigationGroupManager
{
	public var groups:Array<NavigationManager>;
	public var currentGroup(get, null):NavigationManager;

	private var lastFocused:Map<NavigationManager, INavigationInstance>;
	private var portals:Map<INavigationInstance, Map<engine.Direction, PortalTarget>>;

	public function new()
	{
		groups = [];
		currentGroup = null;

		lastFocused = new Map<NavigationManager, INavigationInstance>();
		portals = new Map<INavigationInstance, Map<engine.Direction, PortalTarget>>();
	}

	public function getCurrentGroupIndex():Int
	{
		if (currentGroup == null)
		{
			return -1;
		}
		return groups.indexOf(currentGroup);
	}

	private inline function get_currentGroup():NavigationManager
	{
		return currentGroup;
	}

	public function clearInstancePortals<T:INavigationInstance>(instances:Array<T>)
	{
		for (instance in instances)
		{
			if (portals.exists(instance))
			{
				removePortals(instance);
			}
		}
	}

	public function removePortals(instance:INavigationInstance)
	{
		portals.remove(instance);

		for (i => p in portals)
		{
			for (d => t in p)
			{
				if (t.targetNode == instance)
				{
					p.remove(d);
					break;
				}
			}
		}
	}

	public function disableInteractions()
	{
		for (group in groups)
		{
			group.disableInteractions();
		}
	}

	public function enableInteractions()
	{
		for (group in groups)
		{
			group.enableInteractions();
		}
	}

	public function addGroup(nav:NavigationManager)
	{
		groups.push(nav);
		nav.groupManager = this;
	}

	public function notifyFocused(nav:NavigationManager, instance:INavigationInstance)
	{
		lastFocused.set(nav, instance);
	}

	public function moveToGroup(nav:NavigationManager):Bool
	{
		if (nav == null)
			return false;

		if (currentGroup != null && currentGroup.current != null)
		{
			currentGroup.current.unfocus();
		}

		currentGroup = nav;
		var target = lastFocused.get(nav) ?? getFirst(nav);
		if (target != null)
		{
			nav.select(target);
		}
		return true;
	}

	public function setCurrentGroup(nav:NavigationManager)
	{
		if (currentGroup != nav)
		{
			currentGroup = nav;
			trace('set current group to index ${getCurrentGroupIndex()}');
		}
	}

	private function getFirst(nav:NavigationManager):INavigationInstance
	{
		for (k in nav.instances.keys())
		{
			return k;
		}
		return null;
	}

	/**
		Adds a portal from a node to a specific node in another navigation manager.
	**/
	public function addPortalToNode(from:INavigationInstance, direction:engine.Direction, toNav:NavigationManager, to:INavigationInstance)
	{
		addPortalInternal(from, direction, toNav, to);
	}

	/**
		Adds a portal from a node to the navigation manager itself, allowing for navigation to any node in that manager.
	**/
	public function addPortalToNav(from:INavigationInstance, direction:engine.Direction, toNav:NavigationManager)
	{
		addPortalInternal(from, direction, toNav, null);
	}

	private function addPortalInternal(from:INavigationInstance, direction:engine.Direction, toNav:NavigationManager, to:INavigationInstance)
	{
		if (!portals.exists(from))
		{
			portals.set(from, new Map<engine.Direction, PortalTarget>());
		}
		portals.get(from).set(direction, {targetGroup: toNav, targetNode: to});
	}

	/**
		Tries to move from the current node in the given direction via a portal.
		Returns true if a portal was used, false otherwise.
	**/
	public function tryMove(currentNode:INavigationInstance, direction:engine.Direction):Bool
	{
		if (portals.exists(currentNode))
		{
			var dirMap = portals.get(currentNode);
			if (dirMap.exists(direction))
			{
				var portal = dirMap.get(direction);
				currentGroup = portal.targetGroup;
				var target = portal.targetNode ?? (lastFocused.get(currentGroup) ?? getFirst(currentGroup));

				if (target != null)
					currentGroup.select(target);
				if (target != null)
					lastFocused.set(currentGroup, target);
				return true;
			}
		}
		return false;
	}
}
