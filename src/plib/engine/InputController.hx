package plib.engine;

class InputController<T:EnumValue>
{
	private final stack:Array<InputControllerAccess<T>>;
	private final inputs:Map<T, plib.engine.InputBinding>;
	private final manager:plib.engine.InputManager;

	private var priorityLevel:Int;

	/**
		Note, this is not designed with multiple gamepad in mind.
		This would require a refactor to handle such situation.
	**/
	public function new(manager:plib.engine.InputManager)
	{
		inputs = [];
		this.manager = manager;
		this.stack = [];
	}

	public function canReadInputs(access:InputControllerAccess<T>)
	{
		return stack[stack.length - 1] == access;
	}

	public function removeAccess(access:InputControllerAccess<T>)
	{
		stack.remove(access);
	}

	public function grantAccess(access:InputControllerAccess<T>)
	{
		stack.remove(access);
		stack.push(access);
	}

	/**
		Returns true if the input enum key is set to a binding.
	**/
	public inline function exists(id:T)
	{
		return inputs.exists(id);
	}

	/**
		Returns an input binding from an enum key.
	**/
	public inline function get(id:T)
	{
		return inputs.get(id);
	}

	/**
		Creates a new controller access.
	**/
	public function createAccess()
	{
		var ca = new InputControllerAccess(this);
		stack.push(ca);
		return ca;
	}

	public function registerInput(id:T, btn:plib.engine.PadButton, key:Int, ?dir:Direction)
	{
		var i = manager.createBinding(key, btn);
		i.direction = dir;
		inputs.set(id, i);
	}
}
