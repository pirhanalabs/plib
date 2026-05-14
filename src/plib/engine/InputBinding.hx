package plib.engine;

class InputBinding
{
	public var key(default, null):Int = -1;
	public var button(default, null):Null<PadButton>;
	public var direction:Null<plib.Direction> = null;

	private var manager:InputManager;

	@:allow(plib.engine.InputManager)
	private function new(c:InputManager, key:Int, button:plib.engine.PadButton)
	{
		this.manager = c;
		this.key = key;
		this.button = button;
	}

	public function getName()
	{
		return manager.getString(this);
	}

	public function isPressed()
	{
		return manager.isPressed(this);
	}

	public function isDown()
	{
		return manager.isDown(this);
	}

	public function isReleased()
	{
		return manager.isReleased(this);
	}
}
