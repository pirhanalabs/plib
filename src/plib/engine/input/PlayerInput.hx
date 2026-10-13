package plib.engine.input;

import haxe.ds.ObjectMap;
import plib.M;
import plib.engine.input.InputConfig.InputBinding;
import plib.engine.input.InputConfig.InputComboDefinition;
import plib.engine.input.InputConfig.InputComboKey;
import plib.engine.input.InputConfig.InputScheme;
import plib.engine.input.InputConfig.PadButton;
import plib.engine.input.InputConfig.PadStick;
import plib.engine.input.InputProfile.InputConflictPolicy;
import plib.engine.input.InputSystem.InputBackend;
import plib.engine.input.InputSystem.InputPad;
import plib.engine.input.InputSystem.InputRebind;
import plib.engine.input.InputSystem.InputRebindOptions;
import plib.types.Direction;
import plib.types.Signal;

enum InputMode
{
	None;
	KeyboardMouse;
	Controller;
}

enum InputConnectionState
{
	Empty;
	Listening;
	Connected;
	Disconnected;
}

// Player-facing policy, shared evaluator, and cached action values are kept in
// this module because they exist only to implement PlayerInput handles.

/** Selects which device families a player may observe and optionally locks displayed mode. **/
class InputDevicePolicy
{
	public var keyboard:Bool;
	public var mouse:Bool;
	public var controller:Bool;
	public var lockedMode:Null<InputMode>;

	/** Creates an explicit device policy; a locked mode suppresses automatic mode changes. **/
	public function new(keyboard:Bool = true, mouse:Bool = true, controller:Bool = true, ?lockedMode:InputMode)
	{
		this.keyboard = keyboard;
		this.mouse = mouse;
		this.controller = controller;
		this.lockedMode = lockedMode;
	}

	/** Returns an independent policy with identical values. **/
	public function copy():InputDevicePolicy
		return new InputDevicePolicy(keyboard, mouse, controller, lockedMode);

	/** Allows keyboard, mouse, and controllers. **/
	public static function all():InputDevicePolicy
		return new InputDevicePolicy();

	/** Allows and locks keyboard input. **/
	public static function keyboardOnly():InputDevicePolicy
		return new InputDevicePolicy(true, false, false, KeyboardMouse);

	/** Allows and locks mouse input. **/
	public static function mouseOnly():InputDevicePolicy
		return new InputDevicePolicy(false, true, false, KeyboardMouse);

	/** Allows and locks controller input. **/
	public static function controllerOnly():InputDevicePolicy
		return new InputDevicePolicy(false, false, true, Controller);
}

@:noCompletion
enum PlayerInputChannel
{
	Main;
	Keyboard(scheme:String);
	Controller(pad:InputPad);
}

private class InputPressRecord
{
	public final action:InputKey;
	public final time:Float;

	public function new(action:InputKey, time:Float)
	{
		this.action = action;
		this.time = time;
	}
}

/** Shared configuration, connection, and cached frame state behind player handles. **/
@:noCompletion
@:access(plib.engine.input.InputActionState)
class PlayerInputState
{
	public final id:Int;
	public var connectionState:InputConnectionState;
	public var inputMode:InputMode;
	public var lastInputMode:InputMode;
	public var channel:Null<PlayerInputChannel>;
	public var sessionEnabled:Bool;
	public var waitingForNeutral:Bool;
	public var mouseX:Float = 0;
	public var mouseY:Float = 0;
	public var mouseDX:Float = 0;
	public var mouseDY:Float = 0;
	public var mouseMoved:Bool = false;
	public var directionPressed:Direction = Direction.Center;
	public var directionDown:Direction = Direction.Center;
	public var directionReleased:Direction = Direction.Center;
	public final onInputModeChanged:Signal<InputMode>;

	private final config:InputConfig;
	private final states:ObjectMap<InputKey, InputActionState>;

	public final profile:InputProfile;
	public var devicePolicy:InputDevicePolicy;

	private final pressHistory:Array<InputPressRecord>;
	private final comboPressedState:ObjectMap<InputComboKey, Bool>;
	private var elapsed:Float = 0;
	private var handledFrame:Int = -1;
	private var handledBy:Null<PlayerInput>;
	private final focusStack:Array<InputFocus> = [];

	/** Pushes a temporary input owner for this player only. **/
	public function pushFocus(input:PlayerInput, clearHandlerOnRelease:Bool = false):InputFocus
	{
		var focus:InputFocus = null;
		focus = new InputFocus(input, () -> {
			focusStack.remove(focus);
			if (clearHandlerOnRelease)
				input.setHandler(null);
		});
		focusStack.push(focus);
		return focus;
	}

	public function allowsInput(input:PlayerInput):Bool
		return focusStack.length == 0 || focusStack[focusStack.length - 1].input == input;

	/** Routes once per sampled frame, even when a handler changes focus. **/
	public function routeInputs(fallback:PlayerInput, frame:Int):Bool
	{
		if (handledFrame == frame)
			return false;
		var input = focusStack.length == 0 ? fallback : focusStack[focusStack.length - 1].input;
		return input.handleInputs();
	}

	public function clearFocus():Void
	{
		while (focusStack.length > 0)
			focusStack[focusStack.length - 1].dispose();
	}

	public function new(id:Int, config:InputConfig, state:InputConnectionState = Empty)
	{
		this.id = id;
		this.config = config;
		connectionState = state;
		inputMode = None;
		lastInputMode = None;
		channel = null;
		sessionEnabled = true;
		waitingForNeutral = false;
		onInputModeChanged = new Signal();
		states = new ObjectMap();
		profile = new InputProfile(config);
		devicePolicy = InputDevicePolicy.all();
		pressHistory = [];
		comboPressedState = new ObjectMap();
		for (action in config.actionIterator())
			states.set(action, new InputActionState());
		for (combo in config.comboIterator())
			comboPressedState.set(combo.key, false);
	}

	/** Returns the cached state for one registered logical action. **/
	public inline function state(action:InputKey):InputActionState
	{
		var result = states.get(action);
		if (result == null)
			throw 'Unknown input action: ${action == null ? "null" : action.name}';
		return result;
	}

	public inline function comboPressed(key:InputComboKey):Bool
		return comboPressedState.get(key) == true;

	public function setKeyboardBindings(scheme:String, action:InputKey, bindings:Array<InputBinding>)
	{
		profile.setBindings(scheme, action, bindings);
	}

	public function setControllerBindings(action:InputKey, bindings:Array<InputBinding>)
	{
		profile.setBindings("controller", action, bindings, true);
	}

	public function bindingsFor(scheme:InputScheme, action:InputKey, controller:Bool):Array<InputBinding>
	{
		return profile.bindings(controller ? "controller" : scheme.name, action, controller);
	}

	public function update(backend:InputBackend, dt:Float)
	{
		elapsed += dt;
		mouseX = devicePolicy.mouse ? backend.mouseX() : 0;
		mouseY = devicePolicy.mouse ? backend.mouseY() : 0;
		mouseDX = devicePolicy.mouse ? backend.mouseDX() : 0;
		mouseDY = devicePolicy.mouse ? backend.mouseDY() : 0;
		mouseMoved = false;
		for (combo in config.comboIterator())
			comboPressedState.set(combo.key, false);

		if (connectionState != Connected || channel == null)
		{
			releaseAll();
			return;
		}
		var modeActivity:Null<InputMode> = null;
		if (waitingForNeutral)
		{
			var anyDown = false;
			for (action in config.actionIterator())
				if (evaluateAction(backend, action).down)
					anyDown = true;
			releaseAll();
			if (!anyDown)
				waitingForNeutral = false;
			return;
		}
		var hadPress = false;
		for (action in config.actionIterator())
		{
			var result = evaluateAction(backend, action);
			state(action).update(result.down, result.value, dt);
			if (state(action).pressed && result.mode != null)
				modeActivity = result.mode;
			if (state(action).pressed)
			{
				pressHistory.push(new InputPressRecord(action, elapsed));
				hadPress = true;
			}
		}
		updateDirections();

		var ownsMouse = switch channel
		{
			case Main: true;
			case Keyboard(name): var scheme = config.getKeyboard(name); scheme != null && scheme.includesMouse;
			case Controller(_): false;
		};
		mouseMoved = ownsMouse && (mouseDX != 0 || mouseDY != 0);
		if (mouseMoved)
			modeActivity = KeyboardMouse;
		if (modeActivity != null)
			setMode(modeActivity);

		trimHistory();
		if (hadPress)
			updateCombos();
	}

	private function evaluateAction(backend:InputBackend, action:InputKey):{down:Bool, value:Float, mode:Null<InputMode>}
	{
		return switch channel
		{
			case Main:
				var result = {down: false, value: 0.0, mode: (null : Null<InputMode>)};
				if ((devicePolicy.keyboard || devicePolicy.mouse) && config.defaultKeyboard != null)
				{
					var scheme = config.getKeyboard(config.defaultKeyboard);
					if (scheme != null)
						merge(result, evaluateBindings(backend, null, bindingsFor(scheme, action, false)));
				}
				if (devicePolicy.controller)
					for (pad in backend.pads())
						if (pad.connected)
							merge(result, evaluateBindings(backend, pad, bindingsFor(config.controller, action, true)));
				result;
			case Keyboard(name):
				var scheme = config.getKeyboard(name);
				scheme == null ? {down: false, value: 0.0, mode: null} : evaluateBindings(backend, null, bindingsFor(scheme, action, false));
			case Controller(pad):
				evaluateBindings(backend, pad, bindingsFor(config.controller, action, true));
		};
	}

	private function merge(target:{down:Bool, value:Float, mode:Null<InputMode>}, source:{down:Bool, value:Float, mode:Null<InputMode>})
	{
		if (source.down)
		{
			target.down = true;
			target.value = M.max(target.value, source.value);
		}
		if (source.mode != null)
			target.mode = source.mode;
	}

	private function evaluateBindings(backend:InputBackend, pad:Null<InputPad>, bindings:Array<InputBinding>):{down:Bool, value:Float, mode:Null<InputMode>}
	{
		var result = {down: false, value: 0.0, mode: (null : Null<InputMode>)};
		for (binding in bindings)
		{
			var value = bindingValue(backend, pad, binding);
			if (value > 0)
			{
				result.down = true;
				result.value = M.max(result.value, value);
			}
			if (bindingPressed(backend, pad, binding))
				result.mode = pad == null ? KeyboardMouse : Controller;
		}
		return result;
	}

	private function bindingValue(backend:InputBackend, pad:Null<InputPad>, binding:InputBinding):Float
	{
		return switch binding
		{
			case Key(key): devicePolicy.keyboard && pad == null && backend.keyDown(key) ? 1 : 0;
			case MouseButton(button): devicePolicy.mouse && pad == null && backend.mouseDown(button) ? 1 : 0;
			case PadButton(button): devicePolicy.controller && pad != null && pad.buttonDown(button) ? 1 : 0;
			case StickDirection(stick, direction, threshold):
				if (!devicePolicy.controller || pad == null) 0 else stickDirectionValue(pad, stick, direction, threshold);
			case Chord(bindings):
				var active = bindings.length > 0;
				for (child in bindings)
					if (bindingValue(backend, pad, child) <= 0)
						active = false;
				active ? 1 : 0;
		};
	}

	private function bindingPressed(backend:InputBackend, pad:Null<InputPad>, binding:InputBinding):Bool
	{
		return switch binding
		{
			case Key(key): devicePolicy.keyboard && pad == null && backend.keyPressed(key);
			case MouseButton(button): devicePolicy.mouse && pad == null && backend.mousePressed(button);
			case PadButton(button): devicePolicy.controller && pad != null && pad.buttonPressed(button);
			case StickDirection(stick, direction, threshold): pad != null && stickDirectionValue(pad, stick, direction, threshold) > 0;
			case Chord(_): bindingValue(backend, pad, binding) > 0;
		};
	}

	private function stickDirectionValue(pad:InputPad, stick:PadStick, direction:Direction, threshold:Float):Float
	{
		var x = pad.stickX(stick);
		var y = pad.stickY(stick);
		var magnitude = M.sqrt(x * x + y * y);
		if (magnitude < threshold)
			return 0;
		var horizontal = direction.dx == 0 || (direction.dx < 0 ? x <= -threshold : x >= threshold);
		var vertical = direction.dy == 0 || (direction.dy < 0 ? y <= -threshold : y >= threshold);
		return horizontal && vertical ? M.min(1.0, magnitude) : 0.0;
	}

	private function trimHistory()
	{
		var maxDuration = 0.0;
		for (combo in config.comboIterator())
			maxDuration = M.max(maxDuration, combo.maxDuration);
		while (pressHistory.length > 0 && elapsed - pressHistory[0].time > maxDuration)
			pressHistory.shift();
	}

	private function updateCombos()
	{
		for (combo in config.comboIterator())
		{
			if (pressHistory.length < combo.actions.length)
				continue;
			var start = pressHistory.length - combo.actions.length;
			var matches = true;
			for (index in 0...combo.actions.length)
			{
				var record = pressHistory[start + index];
				if (record.action != combo.actions[index])
					matches = false;
				if (index > 0 && record.time - pressHistory[start + index - 1].time > combo.maxGap)
					matches = false;
			}
			if (pressHistory[pressHistory.length - 1].time - pressHistory[start].time > combo.maxDuration)
				matches = false;
			if (matches)
				comboPressedState.set(combo.key, true);
		}
	}

	private function setMode(mode:InputMode)
	{
		if (devicePolicy.lockedMode != null)
			mode = devicePolicy.lockedMode;
		if (inputMode == mode)
			return;
		inputMode = mode;
		lastInputMode = mode;
		onInputModeChanged.dispatch(mode);
	}

	private function updateDirections()
	{
		directionPressed = aggregateDirection(state -> state.pressed);
		directionDown = aggregateDirection(state -> state.down);
		directionReleased = aggregateDirection(state -> state.released);
	}

	private function aggregateDirection(test:InputActionState->Bool):Direction
	{
		var x = 0;
		var y = 0;
		for (action in config.directionIterator())
		{
			var actionState = state(action);
			if (!test(actionState))
				continue;
			var direction = config.getDirection(action);
			if (direction != null)
			{
				x += direction.dx;
				y += direction.dy;
			}
		}
		return Direction.fromDelta(x, y);
	}

	public function releaseAll()
	{
		for (state in states)
			state.release();
		updateDirections();
		mouseMoved = false;
		if (connectionState != Connected)
			inputMode = None;
	}

	public function claim(handle:PlayerInput, frame:Int):Bool
	{
		if (handledFrame != frame)
		{
			handledFrame = frame;
			handledBy = handle;
			return true;
		}
		if (handledBy == handle)
			return false;
		#if debug
		throw 'Player $id input was handled by multiple handles in one frame.';
		#else
		return false;
		#end
	}
}

/** Cached state returned by `PlayerInput.state()`. **/
class InputActionState
{
	public var pressed(default, null):Bool = false;
	public var down(default, null):Bool = false;
	public var released(default, null):Bool = false;
	public var heldTime(default, null):Float = 0;
	public var value(default, null):Float = 0;

	public function new() {}

	private function update(nextDown:Bool, nextValue:Float, dt:Float)
	{
		var previous = down;
		down = nextDown;
		pressed = !previous && down;
		released = previous && !down;
		value = down ? nextValue : 0;
		heldTime = down ? (previous ? heldTime + dt : 0) : 0;
	}

	private function release()
		update(false, 0, 0);
}

/** Disposable focus ownership. Removing a buried entry does not disturb the current owner. **/
class InputFocus
{
	public final input:PlayerInput;
	private var release:Null<Void->Void>;

	@:allow(plib.engine.input.PlayerInputState)
	private function new(input:PlayerInput, release:Void->Void)
	{
		this.input = input;
		this.release = release;
	}

	/** Restores the previous remaining owner. Safe to call more than once. **/
	public function dispose():Void
	{
		if (release == null) return;
		var callback = release;
		release = null;
		callback();
	}
}

/** Public player facade and independently handled view over shared input state. **/
class PlayerInput
{
	public var sessionEnabled:Bool = true;
	public var handler(default, null):Null<PlayerInput->Void>;

	private final shared:PlayerInputState;
	private final system:InputSystem;

	@:allow(plib.engine.input.InputSystem)
	@:allow(plib.engine.input.InputSession)
	private function new(system:InputSystem, shared:PlayerInputState)
	{
		this.system = system;
		this.shared = shared;
	}

	public var id(get, never):Int;

	private inline function get_id():Int
		return shared.id;

	public var connected(get, never):Bool;

	private inline function get_connected():Bool
		return shared.connectionState == Connected;

	public var connectionState(get, never):InputConnectionState;

	private inline function get_connectionState():InputConnectionState
		return shared.connectionState;

	public var inputMode(get, never):InputMode;

	private inline function get_inputMode():InputMode
		return shared.inputMode;

	public var lastInputMode(get, never):InputMode;

	private inline function get_lastInputMode():InputMode
		return shared.lastInputMode;

	public var onInputModeChanged(get, never):Signal<InputMode>;

	private inline function get_onInputModeChanged():Signal<InputMode>
		return shared.onInputModeChanged;

	public var profile(get, never):InputProfile;

	private inline function get_profile():InputProfile
		return shared.profile;

	public var devicePolicy(get, never):InputDevicePolicy;

	private inline function get_devicePolicy():InputDevicePolicy
		return shared.devicePolicy.copy();

	public var mouseX(get, never):Float;

	private inline function get_mouseX():Float
		return shared.mouseX;

	public var mouseY(get, never):Float;

	private inline function get_mouseY():Float
		return shared.mouseY;

	public var mouseDX(get, never):Float;

	private inline function get_mouseDX():Float
		return shared.mouseDX;

	public var mouseDY(get, never):Float;

	private inline function get_mouseDY():Float
		return shared.mouseDY;

	public var mouseMoved(get, never):Bool;

	private inline function get_mouseMoved():Bool
		return shared.mouseMoved;

	/** Combined pressed state of every action registered with `InputConfig.direction()`. **/
	public var directionPressed(get, never):Direction;

	private inline function get_directionPressed():Direction
		return shared.directionPressed;

	/** Combined held state of every registered directional action. **/
	public var directionDown(get, never):Direction;

	private inline function get_directionDown():Direction
		return shared.directionDown;

	/** Combined released state of every registered directional action. **/
	public var directionReleased(get, never):Direction;

	private inline function get_directionReleased():Direction
		return shared.directionReleased;

	public inline function state(action:InputKey):InputActionState
		return shared.state(action);

	/** Reports whether an action transitioned down this frame. **/
	public inline function pressed(action:InputKey):Bool
		return state(action).pressed;

	/** Reports whether an action is currently held. **/
	public inline function down(action:InputKey):Bool
		return state(action).down;

	/** Reports whether an action transitioned up this frame. **/
	public inline function released(action:InputKey):Bool
		return state(action).released;

	/** Returns seconds continuously held, or zero while up. **/
	public inline function heldTime(action:InputKey):Float
		return state(action).heldTime;

	/** Returns the strongest normalized analog/digital value for an action. **/
	public inline function value(action:InputKey):Float
		return state(action).value;

	/** Reports whether an ordered logical combo completed this frame. **/
	public inline function comboPressed(combo:InputComboKey):Bool
		return shared.comboPressed(combo);

	public var anyPressed(get, never):Bool;

	private function get_anyPressed():Bool
	{
		for (action in system.config.actionIterator())
			if (pressed(action))
				return true;
		return false;
	}

	/** Returns all logical actions newly pressed this frame. **/
	public function pressedInputs():Array<InputKey>
	{
		return [for (action in system.config.actionIterator()) if (pressed(action)) action];
	}

	/** Low-level handler replacement. Prefer pushHandler() for screen-owned input routing. **/
	public inline function setHandler(handler:Null<PlayerInput->Void>)
	{
		this.handler = handler;
	}

	/**
		Registers an input handler above this player's existing handlers.
		Use the same API for gameplay, menus, and nested dialogs: the most recently
		pushed remaining handler receives routed input. The fork is created internally.
		Dispose the returned token when its owner leaves the tree; disposal also
		detaches the callback. Removing a buried handler leaves the top owner active.
		All handles for this player share the stack. Other players are unaffected.
		Input is dispatched by InputSystem.handleInputs() or InputSession.handleInputs().
	**/
	public function pushHandler(handler:PlayerInput->Void):InputFocus
	{
		if (handler == null)
			throw 'Input handler cannot be null.';
		var input = fork();
		input.setHandler(handler);
		return shared.pushFocus(input, true);
	}

	/** Creates an unmanaged handle sharing this player's configuration and state. **/
	public function fork():PlayerInput
	{
		return new PlayerInput(system, shared);
	}

	/**
		Takes temporary focus for this handle. Normally called on a menu fork.
		System/session routing invokes the top focused handle instead of gameplay.
		Dispose the returned token when the menu leaves. Nested focus is supported.
		Focus changes do not clear held inputs or prevent direct state queries.
	**/
	public function takeFocus():InputFocus
		return shared.pushFocus(this);

	/** Routes to this player's focused handle, or this handle when no focus exists. **/
	public function routeInputs():Bool
		return shared.routeInputs(this, system.frameId);

	/** Invokes this handle once for the current sampled frame. **/
	public function handleInputs():Bool
	{
		if (!connected || handler == null || !shared.allowsInput(this) || !shared.claim(this, system.frameId))
			return false;
		handler(this);
		return true;
	}

	/** Replaces the active keyboard mapping for an action. **/
	public function setKeyboardBindings(action:InputKey, bindings:Array<InputBinding>, ?scheme:String)
	{
		var name = scheme;
		if (name == null)
		{
			name = switch shared.channel
			{
				case Keyboard(current): current;
				case Main: system.config.defaultKeyboard;
				case Controller(_): null;
			};
		}
		if (name == null || system.config.getKeyboard(name) == null)
			throw 'A valid keyboard scheme is required for keyboard remapping.';
		shared.setKeyboardBindings(name, action, bindings);
	}

	/** Changes one keyboard binding slot without altering other slots or actions. **/
	public function setKeyboardBinding(action:InputKey, slot:Int, binding:InputBinding, ?scheme:String, policy:InputConflictPolicy = InputConflictPolicy.Allow)
	{
		var name = resolveKeyboardScheme(scheme);
		shared.profile.setBinding(name, action, slot, binding, false, policy);
	}

	/** Replaces the controller mapping for an action using logical controls. **/
	public inline function setControllerBindings(action:InputKey, bindings:Array<InputBinding>)
	{
		shared.setControllerBindings(action, bindings);
	}

	/** Changes one logical controller binding slot. No connected pad is required. **/
	public inline function setControllerBinding(action:InputKey, slot:Int, binding:InputBinding, policy:InputConflictPolicy = InputConflictPolicy.Allow)
	{
		shared.profile.setBinding("controller", action, slot, binding, true, policy);
	}

	/** Restores one keyboard action to config defaults. **/
	public function resetKeyboardAction(action:InputKey, ?scheme:String)
	{
		shared.profile.resetAction(resolveKeyboardScheme(scheme), action);
	}

	/** Restores one controller action to config defaults. **/
	public inline function resetControllerAction(action:InputKey)
	{
		shared.profile.resetAction("controller", action, true);
	}

	/** Clears keyboard overrides for one scheme or all schemes. **/
	public function resetKeyboard(?scheme:String)
	{
		shared.profile.resetScheme(resolveKeyboardScheme(scheme));
	}

	/** Clears every controller binding override. **/
	public inline function resetController()
		shared.profile.resetScheme("controller", true);

	/** Restores all keyboard and controller mappings to config defaults. **/
	public inline function resetAllBindings()
		shared.profile.resetAll();

	/** Serializes this player's remapping profile as portable JSON. **/
	public inline function saveProfile():String
		return shared.profile.toJson();

	/** Replaces remapping overrides from previously serialized profile JSON. **/
	public inline function loadProfile(json:String)
		shared.profile.loadJson(json);

	/** Replaces the device filter. A locked mode remains fixed until the policy changes. **/
	public function setDevicePolicy(policy:InputDevicePolicy)
	{
		if (policy == null)
			throw 'Input device policy cannot be null.';
		shared.devicePolicy = policy.copy();
		if (policy.lockedMode != null)
			@:privateAccess shared.setMode(policy.lockedMode);
		shared.releaseAll();
	}

	/** Begins an interactive remap on this player's assigned channel. **/
	public function rebind(action:InputKey, ?options:InputRebindOptions):InputRebind
	{
		return system.beginRebind(this, action, options);
	}

	private function resolveKeyboardScheme(requested:Null<String>):String
	{
		var name = requested;
		if (name == null)
			name = switch shared.channel
			{
				case Keyboard(current): current;
				case Main, Controller(_), null: system.config.defaultKeyboard;
			};
		if (name == null || system.config.getKeyboard(name) == null)
			throw 'A valid keyboard scheme is required.';
		return name;
	}

	@:allow(plib.engine.input.InputSystem)
	@:allow(plib.engine.input.InputSession)
	private inline function getShared():PlayerInputState
		return shared;
}
