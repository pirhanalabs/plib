package core.navigation;

class BasicNavigationInstance extends h2d.Object implements INavigationInstance
{
	public var navigation:NavigationManager;

	var interactive:h2d.Interactive;

	private function new()
	{
		super();

		interactive = new h2d.Interactive(0, 0, this, null);
		interactive.onOver = onInteractiveOver;
		interactive.onOut = onInteractiveOut;
		interactive.onClick = onInteractiveClick;
	}

	private function onInteractiveOver(e:hxd.Event)
	{
		// override this in subclass to add behavior.
		navigation.select(this);
	}

	private function onInteractiveOut(e:hxd.Event)
	{
		// override this in subclass to add behavior.
	}

	private function onInteractiveClick(e:hxd.Event)
	{
		// override this in subclass to add behavior.
		navigation.execute();
	}

	/**
		This method should be overriden to add behavior.
	**/
	public function execute()
	{
		// override this to add behavior
	}

	public function focus()
	{
		// override this to add behavior
	}

	public function unfocus()
	{
		// override this to add behavior
	}

	public function enableInteractive()
	{
		interactive.cancelEvents = false;
	}

	public function disableInteractive()
	{
		interactive.cancelEvents = true;
	}
}
