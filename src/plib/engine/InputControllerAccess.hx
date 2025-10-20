package plib.engine;

class InputControllerAccess<T:EnumValue>
{
	public var paused:Bool;

	private var controller:InputController<T>;

	@:allow(plib.engine.InputController)
	private var index:Int;

	public function new(controller:InputController<T>)
	{
		this.controller = controller;
		this.index = 0;
		this.paused = false;
	}

	/**
		Give this access the current priority.
		Other access will no longer respond to inputs, except this one.
	**/
	public inline function grantAccess()
	{
		controller.grantAccess(this);
	}

	/**
		Removes the access priority. The last access in the stack will take
		priority again. This is equivalent to a soft dispose. 
	**/
	public inline function revokeAccess()
	{
		controller.removeAccess(this);
	}

	private inline function canReadInputs()
	{
		return !this.paused && controller.canReadInputs(this);
	}

	public function pressed(id:T):Bool
	{
		if (canReadInputs())
		{
			if (controller.exists(id))
			{
				return controller.get(id).isPressed();
			}
		}
		return false;
	}

	public function down(id:T):Bool
	{
		if (canReadInputs())
		{
			if (controller.exists(id))
			{
				return controller.get(id).isDown();
			}
		}
		return false;
	}

	public function released(id:T):Bool
	{
		if (canReadInputs())
		{
			if (controller.exists(id))
			{
				return controller.get(id).isReleased();
			}
		}
		return false;
	}
}
