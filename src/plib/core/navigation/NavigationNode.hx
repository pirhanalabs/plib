package plib.core.navigation;

class NavigationNode
{
	public var instance:INavigationInstance;
	public var previous:Map<plib.EDirection, NavigationNode>;

	private var links:Map<plib.EDirection, NavigationNode>;

	/**
		Handles a navigation instance and all its linked nodes.
	**/
	public function new(instance:INavigationInstance)
	{
		this.instance = instance;
		this.links = new Map<plib.EDirection, NavigationNode>();
		previous = [];
	}

	/**
		Link this node to another one in given direction.
	**/
	public function link(node:NavigationNode, direction:plib.EDirection)
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
	public function getLink(direction:plib.EDirection)
	{
		var reverse = direction.reverse();
		if (previous.exists(reverse))
		{
			return previous.get(reverse);
		}
		return links.get(direction);
	}
}
