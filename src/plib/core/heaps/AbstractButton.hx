package core.heaps;

enum ButtonState
{
	Idle;
	Push;
	Release;
	ReleaseOutside;
	Over;
}

class AbstractButton extends h2d.Object
{
	private var stateVisuals:Map<ButtonState, h2d.Object>;
	private var stateCallbacks:Map<ButtonState, hxd.Event->Void>;
	private var interactive:h2d.Interactive;
	private var state:ButtonState;

	public var width(default, null):Float = 0.0;
	public var height(default, null):Float = 0.0;

	public function new(?parent:h2d.Object)
	{
		super(parent);
		stateVisuals = new Map();
		stateCallbacks = new Map();
		interactive = new h2d.Interactive(width, height, this);
		interactive.onOver = onButtonOver;
		interactive.onOut = onButtonOut;
		interactive.onPush = onButtonPush;
		interactive.onRelease = onButtonRelease;
		interactive.onReleaseOutside = onButtonReleaseOutside;
		this.state = Idle;
	}

	public function allowInteractive(value:Bool)
	{
		this.interactive.cancelEvents = value;
	}

	private function onButtonOver(e:hxd.Event)
	{
		if (this.state == Push)
			return;
		setState(Over);
		triggerCallback(Over, e);
	}

	private function onButtonOut(e:hxd.Event)
	{
		if (this.state == Push)
			return;
		setState(Idle);
		triggerCallback(Idle, e);
	}

	private function onButtonPush(e:hxd.Event)
	{
		setState(Push);
		triggerCallback(Push, e);
	}

	private function onButtonRelease(e:hxd.Event)
	{
		if (e.kind == EReleaseOutside)
			return;

		setState(Idle);
		triggerCallback(Release, e);
	}

	private function onButtonReleaseOutside(e:hxd.Event)
	{
		setState(Idle);
		triggerCallback(ReleaseOutside, e);
	}

	private function triggerCallback(state:ButtonState, e:hxd.Event)
	{
		if (this.stateCallbacks.exists(state))
		{
			this.stateCallbacks.get(state)(e);
		}
	}

	public function forceUpdate()
	{
		updateStateVisuals();
	}

	private function updateStateVisuals()
	{
		var view = stateVisuals.get(this.state);
		if (view == null)
		{
			return;
		}

		if (this.state == null)
		{
			// find a way to allow for invisible button
			// with working interactive
			interactive.width = 0;
			interactive.height = 0;
			this.width = 0;
			this.height = 0;
		}
		else
		{
			var size = view.getSize();
			interactive.width = size.width;
			interactive.height = size.height;
			this.width = interactive.width;
			this.height = interactive.height;
			setStateVisibility(state, true);
		}
	}

	private function setState(state:ButtonState)
	{
		if (this.state != state)
		{
			setStateVisibility(this.state, false);
			this.state = state;
			if (!stateVisualExists(state))
			{
				setState(Idle);
			}
			else
			{
				updateStateVisuals();
			}
		}
	}

	private inline function stateVisualExists(state:ButtonState)
	{
		return stateVisuals.exists(state);
	}

	private function setStateVisibility(state:ButtonState, visible:Bool)
	{
		if (stateVisualExists(state))
		{
			stateVisuals.get(state).visible = visible;
		}
	}

	public function addVisual(state:ButtonState, object:h2d.Object)
	{
		object.visible = false;
		this.addChild(object);
		this.stateVisuals.set(state, object);
	}

	public function addCallback(state:ButtonState, callb:hxd.Event->Void)
	{
		this.stateCallbacks.set(state, callb);
	}
}
