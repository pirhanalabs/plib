package plib.engine;

/**
	Used to represent the last positively read input mode by the input manager.
**/
enum InputMode
{
	Mouse;
	Keyboard;
	Gamepad;
}

/**
	Handles the input system of the game.
	At the moment it only handles a single gamepad at a time (singleplayer).
**/
class InputManager
{
	public var inputMode(default, null):InputMode;

	public final onInputModeChanged:plib.common.utils.AbstractEventDispatcher<InputMode>;

	public var onPadDisconnect:Null<Void->Void>;
	public var onPadConnected:Null<Void->Void>;

	public var pad(default, null):hxd.Pad;

	private var enumBindings:Map<PadButton, Int>;

	public function new()
	{
		inputMode = Keyboard; // default mode is set to keyboard for now.
		onInputModeChanged = new plib.common.utils.AbstractEventDispatcher();
		pad = hxd.Pad.createDummy();
		updateEnumBindings();
		hxd.Pad.wait(_onPadConnected);
	}

	private function _onPadConnected(pad:hxd.Pad)
	{
		this.pad = pad;

		this.pad.onDisconnect = () ->
		{
			if (onPadDisconnect != null)
				onPadDisconnect();
		}

		if (onPadConnected != null)
		{
			onPadConnected();
		}

		updateEnumBindings();
	}

	private function updateEnumBindings()
	{
		enumBindings = new Map();

		enumBindings.set(PadButton.A, pad.config.A);
		enumBindings.set(PadButton.B, pad.config.B);
		enumBindings.set(PadButton.X, pad.config.X);
		enumBindings.set(PadButton.Y, pad.config.Y);

		enumBindings.set(PadButton.RB, pad.config.RB);
		enumBindings.set(PadButton.RT, pad.config.RT);
		enumBindings.set(PadButton.LB, pad.config.LB);
		enumBindings.set(PadButton.LT, pad.config.LT);

		enumBindings.set(PadButton.DPAD_UP, pad.config.dpadUp);
		enumBindings.set(PadButton.DPAD_DOWN, pad.config.dpadDown);
		enumBindings.set(PadButton.DPAD_RIGHT, pad.config.dpadRight);
		enumBindings.set(PadButton.DPAD_LEFT, pad.config.dpadLeft);

		enumBindings.set(PadButton.START, pad.config.start);
		enumBindings.set(PadButton.SELECT, pad.config.back);

		enumBindings.set(PadButton.LSTICK_PUSH, pad.config.analogClick);
		enumBindings.set(PadButton.RSTICK_PUSH, pad.config.ranalogClick);
	}

	@:allow(plib.engine.Application)
	private function onSceneEvent(e:hxd.Event)
	{
		switch (e.kind)
		{
			case EPush:
				setInputMode(Mouse);
			case ERelease:
				setInputMode(Mouse);
			case EMove:
				setInputMode(Mouse);
			case EWheel:
				setInputMode(Mouse);
			case EKeyUp:
				setInputMode(Keyboard);
			case EKeyDown:
				setInputMode(Keyboard);
			default:
		}
	}

	private function setInputMode(mode:InputMode)
	{
		if (inputMode != mode)
		{
			inputMode = mode;
			onInputModeChanged.dispatch(mode);
		}
	}

	public function getPadButtonValue(button:PadButton):Int
	{
		if (enumBindings.exists(button))
		{
			final val = enumBindings.get(button);
			return val;
		}
		return -1;
	}

	public var analogDeadzone:Float = 0.85;

	// u, d, l, r
	private var analogInputs:Map<Int, Float> = [0 => 0.0, 1 => 0.0, 2 => 0.0, 3 => 0.0];

	public function isAnalogPressed(dir:plib.Direction)
	{
		final result = analogInputs[dir.id] == Application.get().frame.frames - 1;
		return result;
	}

	public function isAnalogDown(dir:plib.Direction)
	{
		final result = analogInputs[dir.id] > 0;
		return result;
	}

	public function isAnalogReleased(dir:plib.Direction)
	{
		return analogInputs[dir.id] == -Application.get().frame.frames;
	}

	@:allow(plib.engine.Application)
	private function update(frame:plib.engine.Frame)
	{
		// update analog inputs
		if (pad.connected)
		{
			var deadzone = pad.xAxis * pad.xAxis + pad.yAxis * pad.yAxis < analogDeadzone * analogDeadzone;
			if (deadzone)
			{
				for (direction => value in analogInputs)
				{
					analogInputs[direction] = value > 0 ? -frame.frames : 0;
				}
			}
			else
			{
				var a = MathTools.angle(0, 0, pad.xAxis, pad.yAxis);
				parseAnalogInput(plib.Direction.N, frame, a > -2.25 && a < -1.25);
				parseAnalogInput(plib.Direction.S, frame, a > 1.25 && a < 2.25);
				parseAnalogInput(plib.Direction.W, frame, Math.abs(a) >= 2.70);
				parseAnalogInput(plib.Direction.E, frame, Math.abs(a) <= 0.07);
			}
		}
	}

	private function parseAnalogInput(dir:plib.Direction, frame:plib.engine.Frame, condition:Bool)
	{
		// if the condition was met
		if (condition)
		{
			// and no input was pressed, it is pressed
			if (analogInputs[dir.id] == 0)
			{
				// sets to the current frame
				analogInputs[dir.id] = frame.frames;

				// Unlike Mouse and Keyboard, where we can detect if any key
				// or mouse button are pressed at all, the gamepad does not have
				// this luxury. This means we only set the gamepad input mode if
				// the player clicks one of the registered gamepad's button actions.
				// However, we look for analog stick input when those are changed.
				// Therefore it is more reliable to move the analog sticks to switch
				// input modes. Solving this issue would require checking each input key
				// on a controller individually, which is simply not worth it.
				setInputMode(Gamepad);
			}
		}
		else
		{
			// otherwise, set as negative for 'released' status, and 0 otherwise.
			analogInputs[dir.id] = analogInputs[dir.id] > 0 ? -frame.frames : 0;
		}
	}

	/**
		Creates and returns a new input binding.
	**/
	public function createBinding(key:Int, button:PadButton)
	{
		var binding = new InputBinding(this, key, button);
		return binding;
	}

	public function createDirBinding(dir:plib.Direction, key:Int, button:PadButton)
	{
		var binding = new InputBinding(this, key, button);
		binding.direction = dir;
		return binding;
	}

	/**
		Returns weither or not the given input binding is pressed. 
		NOTE: This works only for keys and pressable buttons on gamepad.
	**/
	public function isPressed(binding:InputBinding)
	{
		if (pad.connected)
		{
			if (pad.isPressed(getPadButtonValue(binding.button)))
			{
				setInputMode(Gamepad);
				return true;
			}
			if (binding.direction != null && isAnalogPressed(binding.direction))
			{
				setInputMode(Gamepad);
				return true;
			}
		}

		var isPressed = hxd.Key.isPressed(binding.key);

		if (isPressed)
		{
			setInputMode(Keyboard);
		}
		return isPressed;
	}

	/**
		Returns weither or not the given input binding is down. 
		NOTE: This works only for keys and pressable buttons on gamepad.
	**/
	public function isDown(binding:InputBinding)
	{
		if (pad.connected)
		{
			if (pad.isDown(getPadButtonValue(binding.button)))
			{
				return true;
			}
			if (binding.direction != null && isAnalogDown(binding.direction))
			{
				return true;
			}
		}

		var isPressed = hxd.Key.isDown(binding.key);

		if (isPressed)
		{
			setInputMode(Keyboard);
		}
		return isPressed;
	}

	/**
		Returns weither or not the given input binding is released. 
		NOTE: This works only for keys and pressable buttons on gamepad.
	**/
	public function isReleased(binding:InputBinding)
	{
		if (pad.connected)
		{
			if (pad.isReleased(getPadButtonValue(binding.button)))
			{
				return true;
			}
			if (binding.direction != null && isAnalogReleased(binding.direction))
			{
				return true;
			}
		}
		return hxd.Key.isReleased(binding.key);
	}

	public function getString(binding:InputBinding)
	{
		return switch (inputMode)
		{
			case Mouse, Keyboard:
				hxd.Key.getKeyName(binding.key);
			case Gamepad:
				// right now, gamepad is english names only.
				switch (binding.button)
				{
					case A: 'A';
					case B: 'B';
					case DPAD_DOWN: 'DPAD DOWN';
					case DPAD_LEFT: 'DPAD LEFT';
					case DPAD_RIGHT: 'DPAD RIGHT';
					case DPAD_UP: 'DPAD UP';
					case LB: 'LB';
					case LSTICK_DOWN: 'LSTICK DOWN';
					case LSTICK_LEFT: 'LSTICK LEFT';
					case LSTICK_PUSH: 'LSTICK PUSH';
					case LSTICK_RIGHT: 'LSTICK RIGHT';
					case LSTICK_UP: 'LSTICK UP';
					case LSTICK_X: 'LSTICK X';
					case LSTICK_Y: 'LSTICK Y';
					case LT: 'LT';
					case RB: 'RB';
					case RSTICK_DOWN: ' RSTICK DOWN';
					case RSTICK_LEFT: 'RSTICK LEFT';
					case RSTICK_PUSH: 'RSTICK PUSH';
					case RSTICK_RIGHT: 'RSTICK RIGHT';
					case RSTICK_UP: 'RSTICK UP';
					case RSTICK_X: 'RSTICK X';
					case RSTICK_Y: 'RSTICK Y';
					case RT: 'RT';
					case SELECT: 'SELECT';
					case START: 'START';
					case X: 'X';
					case Y: 'Y';
					default: hxd.Key.getKeyName(binding.key);
				}
		}
	}
}
