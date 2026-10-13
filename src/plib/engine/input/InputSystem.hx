package plib.engine.input;

import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import plib.engine.input.InputConfig.InputBinding;
import plib.engine.input.InputConfig.PadButton as PButton;
import plib.engine.input.InputConfig.PadStick;
import plib.engine.input.InputProfile.InputConflictPolicy;
import plib.engine.input.InputSession.InputSessionOptions;
import plib.engine.input.PlayerInput.InputConnectionState;
import plib.engine.input.PlayerInput.InputMode;
import plib.engine.input.PlayerInput.PlayerInputChannel;
import plib.engine.input.PlayerInput.PlayerInputState;
import plib.engine.nodes.Node;
import plib.types.Signal;

// -----------------------------------------------------------------------------
// Backend boundary and private Heaps implementation
// -----------------------------------------------------------------------------

/** Hardware boundary used by the Heaps implementation and headless tests. **/
@:noCompletion
interface InputBackend
{
	public function poll():Void;
	public function finishFrame():Void;
	public function dispose():Void;

	public function keyDown(key:Int):Bool;
	public function keyPressed(key:Int):Bool;
	public function keyReleased(key:Int):Bool;
	public function pressedKeys():Iterator<Int>;

	public function mouseDown(button:Int):Bool;
	public function mousePressed(button:Int):Bool;
	public function mouseReleased(button:Int):Bool;
	public function mouseX():Float;
	public function mouseY():Float;
	public function mouseDX():Float;
	public function mouseDY():Float;

	public function pads():Iterator<InputPad>;
}

/** Backend-neutral connected controller. **/
@:noCompletion
interface InputPad
{
	public var id(get, never):Int;
	public var name(get, never):String;
	public var connected(get, never):Bool;
	public var deadzone(get, set):Float;

	public function buttonDown(button:PButton):Bool;
	public function buttonPressed(button:PButton):Bool;
	public function buttonReleased(button:PButton):Bool;
	public function stickX(stick:PadStick):Float;
	public function stickY(stick:PadStick):Float;
}

/** Heaps pad adapter kept private because games work with logical `PButton`s. **/
private class HxdInputPad implements InputPad
{
	private final pad:hxd.Pad;
	private final buttonMap:Array<Int>;

	public function new(pad:hxd.Pad)
	{
		this.pad = pad;
		buttonMap = [];
		var config = pad.config;
		buttonMap[PButton.A] = config.A;
		buttonMap[PButton.B] = config.B;
		buttonMap[PButton.X] = config.X;
		buttonMap[PButton.Y] = config.Y;
		buttonMap[PButton.LB] = config.LB;
		buttonMap[PButton.RB] = config.RB;
		buttonMap[PButton.LT] = config.LT;
		buttonMap[PButton.RT] = config.RT;
		buttonMap[PButton.Start] = config.start;
		buttonMap[PButton.Select] = config.back;
		buttonMap[PButton.DpadUp] = config.dpadUp;
		buttonMap[PButton.DpadDown] = config.dpadDown;
		buttonMap[PButton.DpadLeft] = config.dpadLeft;
		buttonMap[PButton.DpadRight] = config.dpadRight;
		buttonMap[PButton.LeftStick] = config.analogClick;
		buttonMap[PButton.RightStick] = config.ranalogClick;
	}

	public var id(get, never):Int;

	private inline function get_id():Int
		return pad.index;

	public var name(get, never):String;

	private inline function get_name():String
		return pad.name;

	public var connected(get, never):Bool;

	private inline function get_connected():Bool
		return pad.connected;

	public var deadzone(get, set):Float;

	private inline function get_deadzone():Float
		return pad.axisDeadZone;

	private inline function set_deadzone(value:Float):Float
		return pad.axisDeadZone = value;

	private inline function physical(button:PButton):Int
		return buttonMap[button];

	public inline function buttonDown(button:PButton):Bool
		return pad.isDown(physical(button));

	public inline function buttonPressed(button:PButton):Bool
		return pad.isPressed(physical(button));

	public inline function buttonReleased(button:PButton):Bool
		return pad.isReleased(physical(button));

	public inline function stickX(stick:PadStick):Float
		return stick == Left ? pad.xAxis : pad.rxAxis;

	public inline function stickY(stick:PadStick):Float
		return stick == Left ? pad.yAxis : pad.ryAxis;
}

/** Heaps keyboard, mouse, and hot-plug controller backend. **/
private class HxdInputBackend implements InputBackend
{
	private final connectedPads:Array<InputPad> = [];
	private final keysPressed:IntMap<Bool> = new IntMap();
	private var previousMouseX:Float;
	private var previousMouseY:Float;
	private var deltaX:Float = 0;
	private var deltaY:Float = 0;
	private final window:hxd.Window;
	private var disposed:Bool = false;

	public function new(window:hxd.Window)
	{
		this.window = window;
		previousMouseX = window.mouseX;
		previousMouseY = window.mouseY;
		window.addEventTarget(onEvent);
		hxd.Pad.wait(onPadConnected);
	}

	private function onPadConnected(pad:hxd.Pad)
	{
		if (disposed)
			return;
		for (existing in connectedPads)
			if (existing.id == pad.index && existing.connected)
				return;
		var wrapped = new HxdInputPad(pad);
		connectedPads.push(wrapped);
	}

	private function onEvent(event:hxd.Event)
	{
		if (disposed)
			return;
		if (event.kind == EKeyDown)
			keysPressed.set(event.keyCode, true);
	}

	public function poll()
	{
		var x = window.mouseX;
		var y = window.mouseY;
		deltaX = x - previousMouseX;
		deltaY = y - previousMouseY;
		previousMouseX = x;
		previousMouseY = y;
	}

	public function finishFrame()
	{
		keysPressed.clear();
		var index = connectedPads.length - 1;
		while (index >= 0)
		{
			if (!connectedPads[index].connected)
				connectedPads.splice(index, 1);
			index--;
		}
	}

	public function dispose()
	{
		if (disposed)
			return;
		disposed = true;
		window.removeEventTarget(onEvent);
		connectedPads.resize(0);
		keysPressed.clear();
	}

	public inline function keyDown(key:Int):Bool
		return hxd.Key.isDown(key);

	public inline function keyPressed(key:Int):Bool
		return hxd.Key.isPressed(key);

	public inline function keyReleased(key:Int):Bool
		return hxd.Key.isReleased(key);

	public function pressedKeys():Iterator<Int>
		return keysPressed.keys();

	public inline function mouseDown(button:Int):Bool
		return hxd.Key.isDown(button);

	public inline function mousePressed(button:Int):Bool
		return hxd.Key.isPressed(button);

	public inline function mouseReleased(button:Int):Bool
		return hxd.Key.isReleased(button);

	public inline function mouseX():Float
		return window.mouseX;

	public inline function mouseY():Float
		return window.mouseY;

	public inline function mouseDX():Float
		return deltaX;

	public inline function mouseDY():Float
		return deltaY;

	public function pads():Iterator<InputPad>
		return connectedPads.iterator();
}

// -----------------------------------------------------------------------------
// Interactive rebinding
// -----------------------------------------------------------------------------

typedef InputBindingConflict =
{
	var scheme:String;
	var action:InputKey;
	var slot:Int;
}

typedef InputRebindOptions =
{
	@:optional var scheme:String;
	@:optional var controller:Bool;
	@:optional var slot:Int;
	@:optional var conflictPolicy:InputConflictPolicy;
	@:optional var ignored:Array<InputBinding>;
}

@:access(plib.engine.input.InputSystem)
class InputRebind
{
	public final player:PlayerInput;
	public final action:InputKey;
	public final scheme:String;
	public final controller:Bool;
	public final slot:Int;
	public final conflictPolicy:InputConflictPolicy;
	public final ignored:Array<InputBinding>;
	public final onComplete:Signal<InputBinding> = new Signal();
	public final onCancelled:Signal<Bool> = new Signal();
	public final onConflict:Signal<Array<InputBindingConflict>> = new Signal();
	public var complete(default, null):Bool = false;
	public var cancelled(default, null):Bool = false;

	private var armed:Bool = false;
	private final system:InputSystem;

	private function new(system:InputSystem, player:PlayerInput, action:InputKey, scheme:String, controller:Bool, slot:Int, policy:InputConflictPolicy,
			ignored:Array<InputBinding>)
	{
		this.system = system;
		this.player = player;
		this.action = action;
		this.scheme = scheme;
		this.controller = controller;
		this.slot = slot;
		this.conflictPolicy = policy;
		this.ignored = ignored;
	}

	public function cancel()
	{
		if (complete || cancelled)
			return;
		cancelled = true;
		system.cancelRebind(this);
		onCancelled.dispatch(true);
	}

	private function finish(binding:InputBinding)
	{
		complete = true;
		onComplete.dispatch(binding);
	}
}

/** Raw registered activity emitted by `InputSystem.onActivity`. **/
typedef InputActivity =
{
	var mode:InputMode;
	var assigned:Bool;
	var deviceName:String;
	var binding:InputBinding;
}

/** 
	The input system converts physical controls into game actions, then caches their state each frame.

	To make it work, you'll need this input system, a configuration and player bindings, and then
	registering handlers to read the player inputs.

	1. Define your actions via `InputKey`. These represent actions, not keyboard keys or gamepad buttons.

	```
	class Actions{
		public static final JUMP = new plib.engine.input.InputKey("jump");
		public static final ATTACK = new plib.engine.input.InputKey("attack");
	}
	```

	2. Create your input config. This is where you define what button will trigger what action.
	Do this in your application setup, such as `ready()`. An action can have multiple different
	bindings. Bindings support mouse buttons, stick directions, and chords. Chords are combinations
	of inputs held together.

	```
	import plib.engine.input.InputKey;
	import plib.engine.input.InputConfig;
	import plib.engine.input.InputConfig.InputBinding;
	import plib.engine.input.InputConfig.PadButton;

	var config = new InputConfig();
	// register your actions
	config.action(Actions.JUMP);
	config.action(Actions.ATTACK);

	// setup keyboard
	var keyboard = config.keyboard("default");
	keyboard.bind(Actions.JUMP, InputBinding.Key(hxd.Key.SPACE));
	keyboard.bind(Actions.ATTACK, InputBinding.Key(hxd.Key.X));

	// setup secondary keyboard bindings if needed
	var keyboard2 = config.keyboard("player2");
	keyboard2.bind(Actions.JUMP, InputBinding.Key(hxd.Key.UP));
	keyboard2.bind(Actions.ATTACK, InputBinding.Key(hxd.Key.NUMPAD_1));

	// setup controller bindings. These apply to all connected controllers.
	config.controller.bind(Actions.JUMP, InputBinding.PadButton(PadButton.A));
	config.controller.bind(Actions.ATTACK, InputBinding.PadButton(PadButton.X));

	// when done, call this. `inputs` is app.inputs
	inputs.configure(config);
	```

	3. For a single-player game, use inputs.main to read input states:

	```
	var input = Application.get().inputs.main; // or app.inputs.main in a screen node

	var pressed = input.pressed(Actions.JUMP); // true if the action became down this frame
	var down = input.down(Actions.ATTACK); // true if the action is down
	var released = input.released(Actions.ATTACK); // true if the action is released this frame
	var heldTime = input.heldTime(Actions.ATTACK); // seconds the action was held down.
	var value = input.value(Actions.JUMP); // normalized input value for analog bindings.

	if (input.down(Actions.ATTACK)){
		attack();	
	}
	```

	By default, inputs.main combines the default keyboard scheme and controllers.
	The player can switch devices without gameplay code changing.

	4. Use pushHandler() to register input handling for a screen or game character.
	Gameplay, menus, and dialogs all use the same thing. Each player has their own
	handler stack, and only the top handler receives routed input.

	```
	var gameplayFocus = input.pushHandler(function(input){
		if (input.pressed(Actions.JUMP)){
			// do something...
		}
	});
	```

	Keep the returned focus token. When its screen or character leaves, call
	gameplayFocus.dispose() to remove that handler. If another handler was below it,
	that one will resume on the next frame. Disposing a token more than once is fine.

	The application samples input automatically, but you still need to dispatch handlers
	from one update callback. Call inputs.handleInputs() after sampling, such as in a
	node's update(). It routes to inputs.main or the active session's players.

	```
	inputs.handleInputs();
	```

	Direct checks from step 3 still work, but they bypass focus. Use handlers for things
	that should stop responding when a menu takes control. Reading pressed() does not
	consume the press.

	5. Remapping changes a player profile. The defaults belong to InputConfig, but custom
	controls belong to the player's InputProfile.

	```
	input.setKeyboardBinding(Actions.JUMP, 0, InputBinding.Key(hxd.Key.J));
	```

	the `0` means the first binding slot for the JUMP action. Other slots remain unchanged.

	Profiles can be persisted through your settings system:

	```
	app.settings.set("inputProfile", input.saveProfile());
	app.settings.save();
	```

	and can be loaded:

	```
	// after settings have loaded:
	var json:String = app.settings.get('inputProfile', '');
	if (json != ''){
		input.loadProfile(json);	
	}
	```

	Loading a profile can throw if its data is invalid, so handle that when
	restoring saved preferences.

	6. Local multiplayer uses an `InputSession`. It assigns separate devices or
	keyboard schemes to players.

	```
	var session = inputs.createSession({
		capacity: 4,
		minimumPlayers: 1,
		keyboardSchemes: ["default"]
	});

	session.listen();
	```

	While listening, button activity claims an available player slot.
	Once enough players have joined:

	```
	if (session.canStart){
		session.start();	
	}
	```

	Then you use each player's input to push their gameplay handler:

	```
	var playerInput = session.getPlayer(0);
	```

	While a session is active, inputs are read through its players instead
	of inputs.main. inputs.main will no longer update. Sessions also track
	controller disconnections and support replacement controllers.

	The standard way to handle multiple players is as such:

	```
	var session:InputSession;
	var subscriptions:Array<SignalSubscription> = [];
	var gameplayFocuses:Array<plib.engine.input.PlayerInput.InputFocus> = [];

	function openLobby(){
		session = app.inputs.createSession({
			capacity: 4,
			minimumPlayers: 2,
			keyboardSchemes: ["default", "player2"],
		});

		subscriptions.push(session.onPlayerConnected.listen(player->{
			trace('Player ${player.id + 1} joined.');
		}));

		subscriptions.push(session.onReady.listen(_->{
			trace('Enough players have joined.');
			// enable your lobby's Start button.
		}));

		subscriptions.push(session.onPlayerDisconnected.listen(player->{
			trace('Player ${player.id + 1} disconnected.');
			// Show your reconnect UI
		}));

		subscriptions.push(session.onPlayerReconnected.listen(player->{
			trace('Player ${player.id + 1} reconnected.');
		}));

		session.listen();
	}
	```

	A controller press will claim a free player slot.
	A mapped key from registered keyboard schemes will claim a slot for
	that scheme. Devices are assigned as activity is detected and not tied
	to a fixed player number. The session doesnt start when the minimum player count
	is matched. you need to start it manually via an explicit mean, like a start button.
	You can start a lobby by calling something like this:

	```
	function startGame(){
		if (!session.canStart){
			return;	
		}

		session.start();

		for (player in session.players){
			// create or associate your game character here.
			// Bind this player's input to that character.
			var focus = player.pushHandler(input->{
				if (input.down(Actions.ATTACK)){
					trace('player id ${input.id} attacks!');
					// do an attack	
				}else if (input.pressed(Actions.JUMP)){
					trace('player id ${input.id} jumps!');
					// do a jump	
				}
			});
			gameplayFocuses.push(focus);
		}
	}
	```

	You need to call the session's handlers from an update callback, after the application
	has sampled input:

	```haxe
	function updateMatchInputs(){
		if (session.state != Active && session.state != Disconnected){
			return;
		}
		session.handleInputs();
	}
	```

	This lets connected players keep playing while another controller is disconnected.
	If you want to pause everyone instead, only handle inputs while the state is Active.
	Call either session.handleInputs() or inputs.handleInputs(), not both in your update.

	7. A player can open their own menu without stopping the others. The menu uses
	pushHandler() on that same player. It creates a fork internally, sharing the player's
	device, bindings, and input state, but using a separate handler.

	```
	var menuFocus = player.pushHandler(input->{
		if (input.pressed(Actions.JUMP)){
			// confirm the selected menu item...
		}
	});

	// when closing the menu:
	menuFocus.dispose();
	```

	Keep calling session.handleInputs() as before. It sends this player's input to their
	menu and the other players' input to their own current handlers. You dont need to
	change the gameplay handler or manually switch which handle gets called.

	A dialog opened above the menu can push another handler. Closing it restores the
	menu, and closing the menu restores gameplay. Removing a handler from below the
	current one doesnt interrupt that current handler.

	A menu node should keep its token and release it when leaving the tree:

	```
	var focus:plib.engine.input.PlayerInput.InputFocus;

	override function onRemovedFromTree(){
		super.onRemovedFromTree();
		if (focus != null){
			focus.dispose();
		}
	}
	```

	The token is not released automatically when a node leaves. Remember to dispose it.
	Focus changes dont clear held inputs. A button still held when the menu closes can
	be down for gameplay on the next frame, but handlers wont run twice in the same frame.

	Finally, clean up when returning to the menu:

	```
	function closeGame(){
		for (focus in gameplayFocuses){
			focus.dispose();
		}
		gameplayFocuses.resize(0);

		for (subscription in subscriptions){
			subscription.dispose();
		}
		subscriptions.resize(0);
		session.dispose();
	}
	```

	Disposing the session clears its player handlers and focus stacks. Create a new session
	for the next lobby.
**/
@:access(plib.engine.input.InputRebind)
class InputSystem extends Node
{
	// -------------------------------------------------------------------------
	// Construction and public state
	// -------------------------------------------------------------------------

	/** Creates the standard Heaps-backed input system used by `Application`. **/
	public static function createForHeaps(window:hxd.Window):InputSystem
	{
		return new InputSystem(new HxdInputBackend(window));
	}

	/** Advanced injection point for tests and alternate platforms. **/
	@:noCompletion public static function createWithBackend(backend:InputBackend):InputSystem
	{
		return new InputSystem(backend);
	}

	public var config(default, null):InputConfig;
	public var main(default, null):PlayerInput;
	public var activeSession(default, null):Null<InputSession>;
	public var frameId(default, null):Int = 0;
	public final onControllerConnected:Signal<InputPad>;
	public final onControllerDisconnected:Signal<InputPad>;
	public final onInputModeChanged:Signal<InputMode>;
	public final onActivity:Signal<InputActivity>;

	private final backend:InputBackend;
	private final knownPads:ObjectMap<InputPad, Bool>;
	private final rebinds:Array<InputRebind>;
	private var configured:Bool;

	private function new(backend:InputBackend)
	{
		super();
		if (backend == null)
			throw 'InputSystem requires an input backend.';
		this.backend = backend;
		config = new InputConfig();
		main = createMain(config);
		knownPads = new ObjectMap();
		rebinds = [];
		onControllerConnected = new Signal();
		onControllerDisconnected = new Signal();
		onInputModeChanged = new Signal();
		onActivity = new Signal();
		configured = false;
	}

	/** Installs the game's action catalog before sessions are created. **/
	public function configure(config:InputConfig)
	{
		if (config == null)
			throw 'Input configuration cannot be null.';
		if (activeSession != null)
			throw 'Input cannot be reconfigured while a session exists.';
		config.lock();
		this.config = config;
		main = createMain(config);
		configured = true;
	}

	private function createMain(config:InputConfig):PlayerInput
	{
		var shared = new PlayerInputState(-1, config, Connected);
		shared.channel = Main;
		return new PlayerInput(this, shared);
	}

	public function createSession(options:InputSessionOptions):InputSession
	{
		if (!configured)
			throw 'Configure InputSystem before creating an input session.';
		if (activeSession != null)
			throw 'Only one local input session can be active.';
		return new InputSession(this, options);
	}

	@:allow(plib.engine.input.InputSession)
	private function activateSession(session:InputSession)
	{
		if (activeSession != null && activeSession != session)
			throw 'Another input session is already active.';
		activeSession = session;
	}

	@:allow(plib.engine.input.InputSession)
	private function deactivateSession(session:InputSession)
	{
		if (activeSession == session)
			activeSession = null;
	}

	/** Samples hardware and updates all cached action state exactly once. **/
	public function updateState(dt:Float)
	{
		frameId++;
		backend.poll();
		updatePadLifecycle();
		dispatchRawActivity();
		updateRebinds();
		if (activeSession == null)
			@:privateAccess main.getShared().update(backend, dt);
		else
			activeSession.update(backend, dt);
		dispatchGlobalMode();
		backend.finishFrame();
	}

	/** Invokes cached handlers for main input or the active local session. **/
	public function handleInputs():Int
	{
		return activeSession == null ? (main.routeInputs() ? 1 : 0) : activeSession.handleInputs();
	}

	private function dispatchGlobalMode()
	{
		var mode:InputMode = activeSession == null ? main.inputMode : InputMode.None;
		if (activeSession != null)
			for (player in activeSession.players)
				if (player.inputMode != InputMode.None)
					mode = player.inputMode;
		if (globalMode != mode)
		{
			globalMode = mode;
			onInputModeChanged.dispatch(mode);
		}
	}

	public var inputMode(get, never):InputMode;

	private var globalMode:InputMode = InputMode.None;

	private inline function get_inputMode():InputMode
		return globalMode;

	private function updatePadLifecycle()
	{
		var current = new ObjectMap<InputPad, Bool>();
		for (pad in backend.pads())
		{
			if (!pad.connected)
				continue;
			current.set(pad, true);
			if (!knownPads.exists(pad))
			{
				knownPads.set(pad, true);
				onControllerConnected.dispatch(pad);
			}
		}
		var removed:Array<InputPad> = [];
		for (pad in knownPads.keys())
			if (!current.exists(pad) || !pad.connected)
				removed.push(pad);
		for (pad in removed)
		{
			knownPads.remove(pad);
			onControllerDisconnected.dispatch(pad);
		}
	}

	private function dispatchRawActivity()
	{
		var mainPolicy = @:privateAccess main.getShared().devicePolicy;
		if (activeSession != null || mainPolicy.keyboard)
			for (key in backend.pressedKeys())
			{
				var binding:InputBinding = InputBinding.Key(key);
				if (isRegisteredKeyboardBinding(binding))
					onActivity.dispatch({
						mode: KeyboardMouse,
						assigned: activeSession == null || activeSession.isKeyboardBindingAssigned(binding),
						deviceName: "Keyboard/Mouse",
						binding: binding
					});
			}
		if (activeSession != null || mainPolicy.mouse)
			for (button in 0...7)
			{
				if (!backend.mousePressed(button))
					continue;
				var binding:InputBinding = InputBinding.MouseButton(button);
				if (isRegisteredKeyboardBinding(binding))
					onActivity.dispatch({
						mode: KeyboardMouse,
						assigned: activeSession == null || activeSession.isKeyboardBindingAssigned(binding),
						deviceName: "Keyboard/Mouse",
						binding: binding
					});
			}
		if (activeSession != null || mainPolicy.controller)
			for (pad in backend.pads())
				for (button in 0...plib.engine.input.InputConfig.PadButton.COUNT)
				{
					var logical:PButton = cast button;
					if (!pad.buttonPressed(logical) || !isRegisteredControllerButton(logical))
						continue;
					onActivity.dispatch({
						mode: Controller,
						assigned: activeSession == null || activeSession.isPadAssigned(pad),
						deviceName: pad.name,
						binding: InputBinding.PadButton(logical)
					});
				}
	}

	private function isRegisteredKeyboardBinding(binding:InputBinding):Bool
	{
		for (scheme in config.keyboardIterator())
			for (action in scheme.actionIterator())
				for (candidate in scheme.getBindings(action))
					if (bindingContains(candidate, binding))
						return true;
		return false;
	}

	private function isRegisteredControllerButton(button:PButton):Bool
	{
		var binding:InputBinding = InputBinding.PadButton(button);
		for (action in config.controller.actionIterator())
			for (candidate in config.controller.getBindings(action))
				if (bindingContains(candidate, binding))
					return true;
		return false;
	}

	private function bindingContains(candidate:InputBinding, target:InputBinding):Bool
	{
		return switch [candidate, target]
		{
			case [Key(a), Key(b)]: a == b;
			case [MouseButton(a), MouseButton(b)]: a == b;
			case [PadButton(a), PadButton(b)]: a == b;
			case [Chord(bindings), _]:
				var found = false;
				for (child in bindings)
					if (bindingContains(child, target))
						found = true;
				found;
			case _: false;
		};
	}

	@:allow(plib.engine.input.PlayerInput)
	private function beginRebind(player:PlayerInput, action:InputKey, options:Null<InputRebindOptions>):InputRebind
	{
		if (player == null || action == null)
			throw 'Player and action are required for rebinding.';
		for (existing in rebinds)
			if (existing.player.id == player.id)
				throw 'A player can only run one input rebind at a time.';
		var shared = @:privateAccess player.getShared();
		var inferredController = switch shared.channel
		{
			case Controller(_): true;
			case _: false;
		};
		var controller = options != null && options.controller != null ? options.controller : inferredController;
		var scheme = controller ? "controller" : (options != null ? options.scheme : null);
		if (!controller && scheme == null)
			scheme = switch shared.channel
			{
				case Keyboard(name): name;
				case _: config.defaultKeyboard;
			};
		if (!controller && (scheme == null || config.getKeyboard(scheme) == null))
			throw 'Interactive keyboard rebinding requires a valid scheme.';
		var slot = options != null && options.slot != null ? options.slot : 0;
		var policy = options != null && options.conflictPolicy != null ? options.conflictPolicy : InputConflictPolicy.Allow;
		var ignored = options != null && options.ignored != null ? options.ignored.copy() : [];
		// Validate the target before waiting for user input.
		shared.profile.bindings(scheme, action, controller);
		var operation = new InputRebind(this, player, action, scheme, controller, slot, policy, ignored);
		rebinds.push(operation);
		return operation;
	}

	private function cancelRebind(operation:InputRebind)
	{
		rebinds.remove(operation);
	}

	private function updateRebinds()
	{
		for (operation in rebinds.copy())
		{
			if (!operation.armed)
			{
				operation.armed = true;
				continue;
			}
			var binding = detectBinding(operation);
			if (binding == null)
				continue;
			var conflicts = operation.player.profile.conflicts(operation.scheme, operation.action, operation.slot, binding, operation.controller);
			if (conflicts.length > 0 && operation.conflictPolicy == Reject)
			{
				operation.onConflict.dispatch(conflicts);
				continue;
			}
			applyRebind(operation, binding);
			rebinds.remove(operation);
			operation.finish(binding);
		}
	}

	private function detectBinding(operation:InputRebind):Null<InputBinding>
	{
		var result:Null<InputBinding> = null;
		if (operation.controller)
		{
			for (pad in backend.pads())
				if (pad.connected)
					for (button in 0...plib.engine.input.InputConfig.PadButton.COUNT)
						if (pad.buttonPressed(cast button))
						{
							result = PadButton(cast button);
							break;
						}
		}
		else
		{
			for (key in backend.pressedKeys())
			{
				result = Key(key);
				break;
			}
			if (result == null)
				for (button in 0...7)
					if (backend.mousePressed(button))
					{
						result = MouseButton(button);
						break;
					}
		}
		if (result != null)
			for (ignored in operation.ignored)
				if (InputProfile.sameBinding(result, ignored))
					return null;
		return result;
	}

	private function applyRebind(operation:InputRebind, binding:InputBinding)
	{
		var shared = @:privateAccess operation.player.getShared();
		shared.profile.setBinding(operation.scheme, operation.action, operation.slot, binding, operation.controller, operation.conflictPolicy);
		shared.waitingForNeutral = true;
	}

	override function onDestroyed()
	{
		if (activeSession != null)
			activeSession.dispose();
		rebinds.resize(0);
		onControllerConnected.clear();
		onControllerDisconnected.clear();
		onInputModeChanged.clear();
		onActivity.clear();
		backend.dispose();
		super.onDestroyed();
	}
}
