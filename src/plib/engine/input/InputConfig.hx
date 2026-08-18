package plib.engine.input;

import haxe.ds.ObjectMap;
import plib.types.Direction;

/** Logical controller buttons persisted independently of physical pad indices. **/
enum abstract PadButton(Int) from Int to Int
{
	var A = 0;
	var B = 1;
	var X = 2;
	var Y = 3;
	var LB = 4;
	var RB = 5;
	var LT = 6;
	var RT = 7;
	var Start = 8;
	var Select = 9;
	var DpadUp = 10;
	var DpadDown = 11;
	var DpadLeft = 12;
	var DpadRight = 13;
	var LeftStick = 14;
	var RightStick = 15;
	public static inline final COUNT = 16;
}

enum PadStick
{
	Left;
	Right;
}

/** Ordered logical-action sequence identity configured through `InputConfig.combo()`. **/
class InputComboKey
{
	public final name:String;

	public function new(name:String)
	{
		if (name == null || StringTools.trim(name).length == 0)
			throw 'Input combo keys require a name.';
		this.name = name;
	}
}

/** Device-neutral physical binding used by an input scheme or profile. **/
enum InputBinding
{
	Key(key:Int);
	MouseButton(button:Int);
	PadButton(button:plib.engine.input.InputConfig.PadButton);
	StickDirection(stick:PadStick, direction:Direction, threshold:Float);
	Chord(bindings:Array<InputBinding>);
}

@:noCompletion
/** Immutable ordered logical-action sequence recognized by player state. **/
class InputComboDefinition
{
	public final key:InputComboKey;
	public final actions:Array<InputKey>;
	public final maxGap:Float;
	public final maxDuration:Float;

	/** Defines required action order plus per-step and total timing limits. **/
	public function new(key:InputComboKey, actions:Array<InputKey>, maxGap:Float, maxDuration:Float)
	{
		if (key == null || actions == null || actions.length == 0)
			throw 'Input combos require a key and at least one action.';
		if (maxGap < 0 || maxDuration < 0)
			throw 'Input combo timing cannot be negative.';
		this.key = key;
		this.actions = actions.copy();
		this.maxGap = maxGap;
		this.maxDuration = maxDuration;
	}
}

/** Named default mapping configured through `InputConfig.keyboard()` or `controller`. **/
@:noCompletion
/** Named keyboard/mouse or controller mapping from logical actions to physical bindings. **/
class InputScheme
{
	public final name:String;
	public var includesMouse:Bool;

	private final mappings:ObjectMap<InputKey, Array<InputBinding>> = new ObjectMap();
	private var locked:Bool = false;

	/** Creates an empty named scheme; `includesMouse` reserves mouse ownership in sessions. **/
	public function new(name:String, includesMouse:Bool = false)
	{
		if (name == null || StringTools.trim(name).length == 0)
			throw 'Input schemes require a name.';
		this.name = name;
		this.includesMouse = includesMouse;
	}

	/** Appends one binding to an action and returns this scheme for chaining. **/
	public function bind(action:InputKey, binding:InputBinding):InputScheme
	{
		if (locked)
			throw 'Input scheme $name is already configured.';
		if (action == null || binding == null)
			throw 'Input action and binding are required.';
		var values = mappings.get(action);
		if (values == null)
		{
			values = [];
			mappings.set(action, values);
		}
		values.push(binding);
		return this;
	}

	/** Replaces all defaults for an action with a defensive copy. **/
	public function setBindings(action:InputKey, bindings:Array<InputBinding>)
	{
		if (locked)
			throw 'Input scheme $name is already configured.';
		if (action == null)
			throw 'Input action is required.';
		mappings.set(action, bindings == null ? [] : bindings.copy());
	}

	/** Returns a copy of an action's bindings, or an empty array. **/
	public function getBindings(action:InputKey):Array<InputBinding>
	{
		var values = mappings.get(action);
		return values == null ? [] : values;
	}

	/** Iterates actions that have bindings in this scheme. **/
	public function actionIterator():Iterator<InputKey>
		return mappings.keys();

	@:allow(plib.engine.input.InputConfig)
	private function lock()
		locked = true;
}

/** Immutable-at-runtime game action catalog and default mappings. **/
class InputConfig
{
	private final actions:Array<InputKey> = [];
	private final actionNames:Map<String, InputKey> = [];
	private final keyboards:Map<String, InputScheme> = [];
	private final combos:ObjectMap<InputComboKey, InputComboDefinition> = new ObjectMap();
	private final directions:ObjectMap<InputKey, Direction> = new ObjectMap();

	public final controller:InputScheme;
	public var defaultKeyboard(default, null):Null<String>;
	public var controllerDeadzone(default, null):Float = 0.2;

	private var locked:Bool = false;

	/** Creates an empty project input definition with a controller scheme. **/
	public function new()
	{
		controller = new InputScheme("controller");
	}

	/** Registers a logical action and returns this config for chaining. **/
	public function action(key:InputKey):InputConfig
	{
		ensureMutable();
		if (key == null)
			throw 'Input action cannot be null.';
		if (actionNames.exists(key.name))
			throw 'Duplicate input action name: ${key.name}';
		actions.push(key);
		actionNames.set(key.name, key);
		return this;
	}

	/** Creates or returns a named keyboard scheme. **/
	public function keyboard(name:String, includesMouse:Bool = false):InputScheme
	{
		ensureMutable();
		if (keyboards.exists(name))
			throw 'Duplicate keyboard scheme: $name';
		var scheme = new InputScheme(name, includesMouse);
		keyboards.set(name, scheme);
		if (defaultKeyboard == null)
			defaultKeyboard = name;
		return scheme;
	}

	/** Selects the keyboard scheme copied into the main input source by default. **/
	public function setDefaultKeyboard(name:String)
	{
		ensureMutable();
		if (!keyboards.exists(name))
			throw 'Unknown keyboard scheme: $name';
		defaultKeyboard = name;
	}

	/** Sets the normalized global stick deadzone and returns this config. **/
	public function setControllerDeadzone(value:Float):InputConfig
	{
		ensureMutable();
		if (value < 0 || value >= 1)
			throw 'Controller deadzone must be at least 0 and less than 1.';
		controllerDeadzone = value;
		return this;
	}

	/** Registers a non-remappable ordered sequence of logical actions. **/
	public function combo(key:InputComboKey, actions:Array<InputKey>, maxGap:Float = 0.25, maxDuration:Float = 1):InputConfig
	{
		ensureMutable();
		if (combos.exists(key))
			throw 'Input combo is already registered: ${key.name}';
		combos.set(key, new InputComboDefinition(key, actions, maxGap, maxDuration));
		return this;
	}

	/** Marks an action as contributing to the device-neutral directional state. **/
	public function direction(action:InputKey, direction:Direction):InputConfig
	{
		ensureMutable();
		validateAction(action);
		if (direction == Direction.Center)
			throw 'A directional input action cannot use Direction.Center.';
		directions.set(action, direction);
		return this;
	}

	/** Returns a named keyboard scheme when configured. **/
	public inline function getKeyboard(name:String):Null<InputScheme>
		return keyboards.get(name);

	/** Iterates configured keyboard schemes. **/
	public function keyboardIterator():Iterator<InputScheme>
		return keyboards.iterator();

	/** Iterates all registered logical actions. **/
	public function actionIterator():Iterator<InputKey>
		return actions.iterator();

	/** Iterates all registered combo definitions. **/
	public function comboIterator():Iterator<InputComboDefinition>
		return combos.iterator();

	/** Iterates actions mapped to a generic direction. **/
	public function directionIterator():Iterator<InputKey>
		return directions.keys();

	/** Returns the generic direction associated with an action, if any. **/
	public inline function getDirection(action:InputKey):Null<Direction>
		return directions.get(action);

	/** Looks up a combo by stable key. **/
	public inline function getCombo(key:InputComboKey):Null<InputComboDefinition>
		return combos.get(key);

	/** Looks up a logical action by its stable name. **/
	public inline function getAction(name:String):Null<InputKey>
		return actionNames.get(name);

	private function ensureMutable()
	{
		if (locked)
			throw 'Input configuration is already installed.';
	}

	@:allow(plib.engine.input.InputSystem)
	private function lock()
	{
		if (controllerDeadzone < 0 || controllerDeadzone >= 1)
			throw 'Controller deadzone must be at least 0 and less than 1.';
		for (scheme in keyboards)
		{
			validateScheme(scheme);
			scheme.lock();
		}
		validateScheme(controller);
		controller.lock();
		for (combo in combos)
			for (action in combo.actions)
				validateAction(action);
		for (action in directions.keys())
			validateAction(action);
		locked = true;
	}

	private function validateScheme(scheme:InputScheme)
	{
		for (action in scheme.actionIterator())
			validateAction(action);
	}

	private function validateAction(action:InputKey)
	{
		if (action == null || actionNames.get(action.name) != action)
			throw 'Input mapping references an unregistered action: ${action == null ? "null" : action.name}';
	}
}
