package plib.engine;

class InputControllerAccess<T:EnumValue>
{
	private var controller:InputController<T>;

	@:allow(plib.engine.InputController)
	private var index:Int;

	public function new(controller:InputController<T>)
	{
		this.controller = controller;
		this.index = 0;
	}

	public inline function grantAccess()
	{
		controller.grantAccess(this);
	}

	public inline function revokeAccess()
	{
		controller.removeAccess(this);
	}

	public function pressed(id:T):Bool
	{
		if (controller.canReadInputs(this))
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
		if (controller.canReadInputs(this))
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
		if (controller.canReadInputs(this))
		{
			if (controller.exists(id))
			{
				return controller.get(id).isReleased();
			}
		}
		return false;
	}
}
