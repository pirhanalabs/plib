package core.navigation;

class NavigationNode
{
	public var instance:INavigationInstance;
	public var previous:Map<engine.Direction, NavigationNode>;

	private var links:Map<engine.Direction, NavigationNode>;

	/**
		Handles a navigation instance and all its linked nodes.
	**/
	public function new(instance:INavigationInstance)
	{
		this.instance = instance;
		this.links = new Map<engine.Direction, NavigationNode>();
		previous = [];
	}

	/**
		Link this node to another one in given direction.
	**/
	public function link(node:NavigationNode, direction:engine.Direction)
	{
		if (links.exists(direction))
			return false;
		links.set(direction, node);
		return true;
	}

	public function clearLinks()
	{
		links.clear();
		previous.clear();
	}

	/**
		Returns the link (if any) in given direction.
	**/
	public function getLink(direction:engine.Direction)
	{
		var reverse = direction.getReverse();
		if (previous.exists(reverse))
		{
			return previous.get(reverse);
		}
		return links.get(direction);
	}
}
