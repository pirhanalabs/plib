package plib.engine.input;

import haxe.ds.ObjectMap;
import plib.engine.input.InputConfig.InputBinding;
import plib.engine.input.InputConfig.PadButton;
import plib.engine.input.InputSystem.InputBackend;
import plib.engine.input.InputSystem.InputPad;
import plib.engine.input.PlayerInput.InputConnectionState;
import plib.engine.input.PlayerInput.PlayerInputChannel;
import plib.engine.input.PlayerInput.PlayerInputState;
import plib.types.Signal;

typedef InputSessionOptions =
{
	var capacity:Int;
	var minimumPlayers:Int;
	@:optional var keyboardSchemes:Array<String>;
}

enum InputSessionState
{
	Idle;
	Registering;
	Ready;
	Active;
	Disconnected;
	Ended;
}

/** Local input registration and routing group, independent from network play. **/
class InputSession
{
	/** Maximum number of registration slots created by this session. **/
	public final capacity:Int;

	/** Connected players required before `start` is allowed. **/
	public final minimumPlayers:Int;

	/** Current registration/gameplay lifecycle state. **/
	public var state(default, null):InputSessionState;

	/** Allows activity from a free pad to reclaim a disconnected active player. **/
	public var autoReconnect:Bool = true;

	/** Fired when a listening slot first claims a keyboard scheme or pad. **/
	public final onPlayerConnected:Signal<PlayerInput>;

	/** Fired when an active player's assigned pad disappears. **/
	public final onPlayerDisconnected:Signal<PlayerInput>;

	/** Fired after replacement hardware claims a disconnected player. **/
	public final onPlayerReconnected:Signal<PlayerInput>;

	/** Fired once registration first satisfies `minimumPlayers`. **/
	public final onReady:Signal<InputSession>;

	private final system:InputSystem;
	private final allPlayers:Array<PlayerInput>;
	private final activePlayers:Array<PlayerInput>;
	private final keyboardSchemes:Array<String>;
	private final keyboardAssignments:Map<String, PlayerInput>;
	private final padAssignments:ObjectMap<InputPad, PlayerInput>;
	private var wasReady:Bool;
	private var replacementPriority:Null<PlayerInput>;

	@:allow(plib.engine.input.InputSystem)
	private function new(system:InputSystem, options:InputSessionOptions)
	{
		if (options.capacity <= 0)
			throw 'Input session capacity must be positive.';
		if (options.minimumPlayers <= 0 || options.minimumPlayers > options.capacity)
			throw 'Input session minimum must be within its capacity.';
		this.system = system;
		capacity = options.capacity;
		minimumPlayers = options.minimumPlayers;
		keyboardSchemes = options.keyboardSchemes == null ? [] : options.keyboardSchemes.copy();
		for (name in keyboardSchemes)
			if (system.config.getKeyboard(name) == null)
				throw 'Unknown keyboard scheme: $name';
		validateKeyboardSchemes();
		allPlayers = [];
		activePlayers = [];
		keyboardAssignments = [];
		padAssignments = new ObjectMap();
		onPlayerConnected = new Signal();
		onPlayerDisconnected = new Signal();
		onPlayerReconnected = new Signal();
		onReady = new Signal();
		state = Idle;
		wasReady = false;
		replacementPriority = null;
		for (index in 0...capacity)
		{
			var shared = new PlayerInputState(index, system.config);
			allPlayers.push(new PlayerInput(system, shared));
		}
	}

	private function validateKeyboardSchemes()
	{
		var controls:Map<String, String> = [];
		var mouseOwner:Null<String> = null;
		for (name in keyboardSchemes)
		{
			var scheme = system.config.getKeyboard(name);
			if (scheme.includesMouse)
			{
				if (mouseOwner != null)
					throw 'Only one local keyboard scheme can own the mouse: $mouseOwner and $name';
				mouseOwner = name;
			}
			for (action in scheme.actionIterator())
				for (binding in scheme.getBindings(action))
					validateKeyboardBinding(name, binding, controls);
		}
	}

	private function validateKeyboardBinding(scheme:String, binding:InputBinding, controls:Map<String, String>)
	{
		var identifier:Null<String> = switch binding
		{
			case Key(key): 'key:$key';
			case MouseButton(button): 'mouse:$button';
			case Chord(bindings):
				for (child in bindings)
					validateKeyboardBinding(scheme, child, controls);
				null;
			case _: null;
		};
		if (identifier == null)
			return;
		var existing = controls.get(identifier);
		if (existing != null && existing != scheme)
			throw 'Keyboard schemes $existing and $scheme overlap on $identifier.';
		controls.set(identifier, scheme);
	}

	/** Number of slots currently backed by an active input channel. **/
	public var connectedCount(get, never):Int;

	private function get_connectedCount():Int
	{
		var count = 0;
		for (player in allPlayers)
			if (player.connected)
				count++;
		return count;
	}

	/** Whether registration currently satisfies the minimum and may start. **/
	public var canStart(get, never):Bool;

	private inline function get_canStart():Bool
		return (state == Registering || state == Ready) && connectedCount >= minimumPlayers;

	/** Snapshot of registration slots, or finalized active players after `start`. **/
	public var players(get, never):Array<PlayerInput>;

	private inline function get_players():Array<PlayerInput>
		return (state == Active || state == Disconnected) ? activePlayers.copy() : allPlayers.copy();

	/** Returns a registration/active player by session order. **/
	public function getPlayer(index:Int):PlayerInput
	{
		var source = (state == Active || state == Disconnected) ? activePlayers : allPlayers;
		if (index < 0 || index >= source.length)
			throw 'Input player index is outside this session.';
		return source[index];
	}

	/** Begins join-by-input registration and makes this the system's active session. **/
	public function listen()
	{
		if (state != Idle)
			throw 'Only an idle input session can begin registration.';
		system.activateSession(this);
		state = Registering;
		for (player in allPlayers)
			@:privateAccess player.getShared().connectionState = Listening;
	}

	/** Freezes connected registrations into the active player list. **/
	public function start()
	{
		if (!canStart)
			throw 'Input session does not have enough connected players.';
		activePlayers.resize(0);
		for (player in allPlayers)
			if (player.connected)
				activePlayers.push(player);
		allPlayers.resize(0);
		for (player in activePlayers)
			allPlayers.push(player);
		state = Active;
	}

	/** Invokes active player handlers once and returns how many handlers ran. **/
	public function handleInputs():Int
	{
		if (state != Active && state != Disconnected)
			return 0;
		var handled = 0;
		for (player in activePlayers)
			if (player.sessionEnabled && player.routeInputs())
				handled++;
		return handled;
	}

	/** Returns a snapshot of active players awaiting replacement hardware. **/
	public function disconnectedPlayers():Array<PlayerInput>
	{
		return [for (player in activePlayers) if (player.connectionState == Disconnected) player];
	}

	/** Gives one disconnected player priority for the next unassigned pad activity. **/
	public function listenForReplacement(player:PlayerInput)
	{
		if (activePlayers.indexOf(player) < 0 || player.connectionState != Disconnected)
			throw 'Only a disconnected active player can request replacement input.';
		replacementPriority = player;
	}

	/** Ends registration/routing, clears handlers, and releases device assignments. **/
	public function dispose()
	{
		if (state == Ended)
			return;
		state = Ended;
		system.deactivateSession(this);
		keyboardAssignments.clear();
		padAssignments.clear();
		for (player in allPlayers)
		{
			player.setHandler(null);
			var shared = @:privateAccess player.getShared();
			shared.clearFocus();
			shared.connectionState = Empty;
			shared.channel = null;
			shared.releaseAll();
		}
	}

	@:allow(plib.engine.input.InputSystem)
	private function update(backend:InputBackend, dt:Float)
	{
		detectDisconnects();
		if (state == Registering || state == Ready || (state == Disconnected && autoReconnect))
			registerActivity(backend);
		var source = (state == Active || state == Disconnected) ? activePlayers : allPlayers;
		for (player in source)
			@:privateAccess player.getShared().update(backend, dt);
		updateState();
	}

	private function detectDisconnects()
	{
		for (player in allPlayers)
		{
			var shared = @:privateAccess player.getShared();
			switch shared.channel
			{
				case Controller(pad) if (!pad.connected && shared.connectionState == Connected):
					padAssignments.remove(pad);
					shared.channel = null;
					shared.connectionState = Disconnected;
					shared.releaseAll();
					onPlayerDisconnected.dispatch(player);
				case _:
			}
		}
	}

	private function registerActivity(backend:InputBackend)
	{
		for (pad in backend.pads())
		{
			if (!pad.connected || padAssignments.exists(pad) || !padHasJoinActivity(pad))
				continue;
			var player = firstDisconnected();
			var reconnecting = player != null;
			if (player == null && (state == Registering || state == Ready))
				player = firstListening();
			if (player != null)
				assignPad(player, pad, reconnecting);
		}
		if (state != Registering && state != Ready)
			return;
		for (name in keyboardSchemes)
		{
			if (keyboardAssignments.exists(name) || !keyboardHasJoinActivity(backend, name))
				continue;
			var player = firstListening();
			if (player != null)
				assignKeyboard(player, name);
		}
	}

	private function firstListening():Null<PlayerInput>
	{
		for (player in allPlayers)
			if (player.connectionState == Listening)
				return player;
		return null;
	}

	private function firstDisconnected():Null<PlayerInput>
	{
		if (replacementPriority != null && replacementPriority.connectionState == Disconnected)
			return replacementPriority;
		for (player in activePlayers)
			if (player.connectionState == Disconnected)
				return player;
		return null;
	}

	private function assignPad(player:PlayerInput, pad:InputPad, reconnecting:Bool)
	{
		pad.deadzone = system.config.controllerDeadzone;
		padAssignments.set(pad, player);
		var shared = @:privateAccess player.getShared();
		shared.channel = Controller(pad);
		shared.connectionState = Connected;
		shared.waitingForNeutral = true;
		if (replacementPriority == player)
			replacementPriority = null;
		if (reconnecting)
			onPlayerReconnected.dispatch(player);
		else
			onPlayerConnected.dispatch(player);
	}

	private function assignKeyboard(player:PlayerInput, name:String)
	{
		keyboardAssignments.set(name, player);
		var shared = @:privateAccess player.getShared();
		shared.channel = Keyboard(name);
		shared.connectionState = Connected;
		shared.waitingForNeutral = true;
		onPlayerConnected.dispatch(player);
	}

	private function updateState()
	{
		if (state == Ended || state == Idle)
			return;
		if (state == Active || state == Disconnected)
		{
			state = disconnectedPlayers().length > 0 ? Disconnected : Active;
			return;
		}
		var ready = connectedCount >= minimumPlayers;
		state = ready ? Ready : Registering;
		if (ready && !wasReady)
			onReady.dispatch(this);
		wasReady = ready;
	}

	private function padHasJoinActivity(pad:InputPad):Bool
	{
		for (button in 0...plib.engine.input.InputConfig.PadButton.COUNT)
			if (pad.buttonPressed(cast button))
				return true;
		return false;
	}

	private function keyboardHasJoinActivity(backend:InputBackend, name:String):Bool
	{
		var scheme = system.config.getKeyboard(name);
		if (scheme == null)
			return false;
		for (action in scheme.actionIterator())
			for (binding in scheme.getBindings(action))
				if (keyboardBindingPressed(backend, binding))
					return true;
		return false;
	}

	private function keyboardBindingPressed(backend:InputBackend, binding:InputBinding):Bool
	{
		return switch binding
		{
			case Key(key): backend.keyPressed(key);
			case MouseButton(button): backend.mousePressed(button);
			case Chord(bindings):
				var pressed = false;
				for (child in bindings)
					if (keyboardBindingPressed(backend, child))
						pressed = true;
				pressed;
			case _: false;
		};
	}

	@:allow(plib.engine.input.InputSystem)
	private inline function isPadAssigned(pad:InputPad):Bool
		return padAssignments.exists(pad);

	@:allow(plib.engine.input.InputSystem)
	private function isKeyboardBindingAssigned(binding:InputBinding):Bool
	{
		for (name in keyboardAssignments.keys())
		{
			var scheme = system.config.getKeyboard(name);
			if (scheme == null)
				continue;
			for (action in scheme.actionIterator())
				for (candidate in scheme.getBindings(action))
					if (sameBinding(candidate, binding))
						return true;
		}
		return false;
	}

	private function sameBinding(left:InputBinding, right:InputBinding):Bool
	{
		return switch [left, right]
		{
			case [Key(a), Key(b)]: a == b;
			case [MouseButton(a), MouseButton(b)]: a == b;
			case [PadButton(a), PadButton(b)]: a == b;
			case _: false;
		};
	}
}
