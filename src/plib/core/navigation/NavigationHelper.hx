package core.navigation;

class NavigationHelper
{
	/**
		Connects an array of INavigationInstance instances in a linear fashion, in the given direction.
		This makes a two-way link between each instance.
	**/
	public static function buildLinear<T:INavigationInstance>(nav:NavigationManager, direction:engine.Direction, instances:Array<T>)
	{
		for (i in 0...instances.length - 1)
		{
			var a = instances[i];
			var b = instances[i + 1];
			nav.link2(a, b, direction);
		}
	}

	/**
		Adds a portal to the navigation group, which will lead to the given navigation manager.
		The portal will be created for each instance in the given direction.
	**/
	public static function buildPortalToNav<T:INavigationInstance>(group:NavigationGroupManager, nav:NavigationManager, direction:engine.Direction,
			instances:Array<T>)
	{
		for (i in 0...instances.length)
		{
			group.addPortalToNav(instances[i], direction, nav);
		}
	}

	/**
		Connects a grid of INavigationInstance instances in a two-dimensional grid.
		This makes a two-way link between each instance in the grid.
	**/
	public static function buildGrid2D<T:INavigationInstance>(nav:NavigationManager, grid:Array<Array<Null<T>>>)
	{
		var rows = grid.length;
		var cols = grid[0].length;

		for (y in 0...rows)
		{
			for (x in 0...cols)
			{
				var cell = grid[y][x];
				if (cell == null)
					continue;

				// left
				if (x > 0 && grid[y][x - 1] != null)
					nav.link2(cell, grid[y][x - 1], engine.Direction.W);
				// right
				if (x < cols - 1 && grid[y][x + 1] != null)
					nav.link2(cell, grid[y][x + 1], engine.Direction.E);
				// up
				if (y > 0 && grid[y - 1][x] != null)
					nav.link2(cell, grid[y - 1][x], engine.Direction.N);
				// down
				if (y < rows - 1 && grid[y + 1][x] != null)
					nav.link2(cell, grid[y + 1][x], engine.Direction.S);
			}
		}
	}
}
