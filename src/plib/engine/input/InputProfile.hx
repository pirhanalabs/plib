package plib.engine.input;

import haxe.ds.ObjectMap;
import plib.engine.input.InputConfig.InputBinding;
import plib.engine.input.InputConfig.InputScheme;
import plib.engine.input.InputConfig.PadButton;
import plib.engine.input.InputConfig.PadStick;
import plib.engine.input.InputSystem.InputBindingConflict;
import plib.types.Direction;

enum InputConflictPolicy
{
	Allow;
	Reject;
	ReplaceExisting;
}

/** Serializable per-player binding overrides layered over an immutable `InputConfig`. **/
class InputProfile
{
	public static inline final VERSION = 1;

	private final config:InputConfig;
	private final keyboards:Map<String, ObjectMap<InputKey, Array<InputBinding>>> = [];
	private final controller:ObjectMap<InputKey, Array<InputBinding>> = new ObjectMap();

	@:allow(plib.engine.input.PlayerInput.PlayerInputState)
	public function new(config:InputConfig)
	{
		if (config == null)
			throw 'InputProfile requires an InputConfig.';
		this.config = config;
	}

	/** Returns the effective bindings, including defaults when no override exists. **/
	public function bindings(scheme:String, action:InputKey, isController:Bool = false):Array<InputBinding>
	{
		validateAction(action);
		if (isController)
		{
			var custom = controller.get(action);
			return (custom == null ? config.controller.getBindings(action) : custom).copy();
		}
		var source = requireKeyboard(scheme);
		var overrides = keyboards.get(scheme);
		var custom = overrides == null ? null : overrides.get(action);
		return (custom == null ? source.getBindings(action) : custom).copy();
	}

	/** Finds other slots in the same device scheme that contain `binding`. **/
	public function conflicts(scheme:String, action:InputKey, slot:Int, binding:InputBinding, isController:Bool = false):Array<InputBindingConflict>
	{
		validateTarget(scheme, action, slot, isController, true);
		var result:Array<InputBindingConflict> = [];
		for (candidateAction in config.actionIterator())
		{
			var values = bindings(scheme, candidateAction, isController);
			for (index in 0...values.length)
				if ((candidateAction != action || index != slot) && sameBinding(values[index], binding))
					result.push({scheme: isController ? "controller" : scheme, action: candidateAction, slot: index});
		}
		return result;
	}

	/** Changes exactly one displayed binding slot. `slot == length` appends a new slot. **/
	public function setBinding(scheme:String, action:InputKey, slot:Int, binding:InputBinding, isController:Bool = false,
			policy:InputConflictPolicy = InputConflictPolicy.Allow)
	{
		if (binding == null)
			throw 'Input binding cannot be null.';
		validateTarget(scheme, action, slot, isController, true);
		var found = conflicts(scheme, action, slot, binding, isController);
		if (found.length > 0 && policy == Reject)
			throw 'Input binding conflicts with ${found.length} existing binding slot(s).';
		if (policy == ReplaceExisting)
		{
			var originalSlot = slot;
			for (conflict in found)
				if (conflict.action == action && conflict.slot < originalSlot)
					slot--;
			clearOtherOccurrences(scheme, action, originalSlot, binding, isController);
		}

		var values = bindings(scheme, action, isController);
		// Earlier removals can shift this action's requested slot.
		if (slot > values.length)
			slot = values.length;
		if (slot == values.length)
			values.push(binding);
		else
			values[slot] = binding;
		setOverride(scheme, action, values, isController);
	}

	private function clearOtherOccurrences(scheme:String, targetAction:InputKey, targetSlot:Int, binding:InputBinding, isController:Bool)
	{
		for (candidateAction in config.actionIterator())
		{
			var values = bindings(scheme, candidateAction, isController);
			var filtered:Array<InputBinding> = [];
			for (index in 0...values.length)
				if ((candidateAction == targetAction && index == targetSlot) || !sameBinding(values[index], binding))
					filtered.push(values[index]);
			if (filtered.length != values.length)
				setOverride(scheme, candidateAction, filtered, isController);
		}
	}

	/** Removes one binding slot without affecting another action using the same key. **/
	public function removeBinding(scheme:String, action:InputKey, slot:Int, isController:Bool = false)
	{
		validateTarget(scheme, action, slot, isController, false);
		var values = bindings(scheme, action, isController);
		values.splice(slot, 1);
		setOverride(scheme, action, values, isController);
	}

	public function setBindings(scheme:String, action:InputKey, values:Array<InputBinding>, isController:Bool = false)
	{
		validateAction(action);
		if (!isController)
			requireKeyboard(scheme);
		setOverride(scheme, action, values == null ? [] : values.copy(), isController);
	}

	/** Restores one action to its configured defaults. **/
	public function resetAction(scheme:String, action:InputKey, isController:Bool = false)
	{
		validateAction(action);
		if (isController)
			controller.remove(action);
		else
		{
			requireKeyboard(scheme);
			var overrides = keyboards.get(scheme);
			if (overrides != null)
				overrides.remove(action);
		}
	}

	/** Restores every action for one scheme to configured defaults. **/
	public function resetScheme(scheme:String, isController:Bool = false)
	{
		if (isController)
			controller.clear();
		else
		{
			requireKeyboard(scheme);
			keyboards.remove(scheme);
		}
	}

	public function resetAll()
	{
		keyboards.clear();
		controller.clear();
	}

	/** Produces JSON containing only per-player overrides, using stable action names. **/
	public function toJson():String
	{
		var keyboardData:Array<Dynamic> = [];
		for (name in keyboards.keys())
			keyboardData.push({name: name, actions: encodeActions(keyboards.get(name))});
		return haxe.Json.stringify({version: VERSION, keyboards: keyboardData, controller: encodeActions(controller)});
	}

	/** Replaces this profile's overrides from persisted JSON. **/
	public function loadJson(json:String)
	{
		var data:Dynamic = haxe.Json.parse(json);
		if (data == null || data.version != VERSION)
			throw 'Unsupported input profile version.';
		resetAll();
		for (entry in (cast data.keyboards : Array<Dynamic>))
		{
			var name:String = entry.name;
			requireKeyboard(name);
			decodeActions(name, entry.actions, false);
		}
		decodeActions("controller", data.controller, true);
	}

	private function encodeActions(source:ObjectMap<InputKey, Array<InputBinding>>):Array<Dynamic>
	{
		var result:Array<Dynamic> = [];
		if (source != null)
			for (action in source.keys())
				result.push({action: action.name, bindings: [for (binding in source.get(action)) encodeBinding(binding)]});
		return result;
	}

	private function decodeActions(scheme:String, entries:Array<Dynamic>, isController:Bool)
	{
		if (entries == null)
			return;
		for (entry in entries)
		{
			var action = config.getAction(entry.action);
			if (action == null)
				continue; // Profiles survive removed actions.
			var values:Array<InputBinding> = [for (value in (cast entry.bindings : Array<Dynamic>)) decodeBinding(value)];
			setOverride(scheme, action, values, isController);
		}
	}

	private function encodeBinding(binding:InputBinding):Dynamic
	{
		return switch binding
		{
			case Key(key): {type: "key", value: key};
			case MouseButton(button): {type: "mouse", value: button};
			case PadButton(button): {type: "pad", value: (button : Int)};
			case StickDirection(stick, direction, threshold):
				{
					type: "stick",
					stick: Std.string(stick),
					dx: direction.dx,
					dy: direction.dy,
					threshold: threshold
				};
			case Chord(children): {type: "chord", bindings: [for (child in children) encodeBinding(child)]};
		};
	}

	private function decodeBinding(value:Dynamic):InputBinding
	{
		return switch (value.type : String)
		{
			case "key": Key(value.value);
			case "mouse": MouseButton(value.value);
			case "pad": PadButton(cast(value.value : Int));
			case "stick": StickDirection(value.stick == "Right" ? Right : Left, Direction.from(value.dx, value.dy), value.threshold);
			case "chord": Chord([for (child in (cast value.bindings : Array<Dynamic>)) decodeBinding(child)]);
			case unknown: throw 'Unknown persisted input binding type: $unknown';
		};
	}

	private function setOverride(scheme:String, action:InputKey, values:Array<InputBinding>, isController:Bool)
	{
		if (isController)
			controller.set(action, values);
		else
		{
			var overrides = keyboards.get(scheme);
			if (overrides == null)
			{
				overrides = new ObjectMap();
				keyboards.set(scheme, overrides);
			}
			overrides.set(action, values);
		}
	}

	private function validateTarget(scheme:String, action:InputKey, slot:Int, isController:Bool, allowAppend:Bool)
	{
		var values = bindings(scheme, action, isController);
		var maximum = allowAppend ? values.length : values.length - 1;
		if (slot < 0 || slot > maximum)
			throw 'Input binding slot is outside this action.';
	}

	private function validateAction(action:InputKey)
	{
		if (action == null || config.getAction(action.name) != action)
			throw 'Input profile references an unregistered action.';
	}

	private function requireKeyboard(name:String):InputScheme
	{
		var scheme = config.getKeyboard(name);
		if (scheme == null)
			throw 'Unknown keyboard scheme: $name';
		return scheme;
	}

	public static function sameBinding(a:InputBinding, b:InputBinding):Bool
	{
		return switch [a, b]
		{
			case [Key(x), Key(y)]: x == y;
			case [MouseButton(x), MouseButton(y)]: x == y;
			case [PadButton(x), PadButton(y)]: x == y;
			case [StickDirection(xs, xd, xt), StickDirection(ys, yd, yt)]: xs == ys && xd == yd && xt == yt;
			case [Chord(xs), Chord(ys)]:
				if (xs.length != ys.length) false else
				{
					var equal = true;
					for (index in 0...xs.length)
						if (!sameBinding(xs[index], ys[index]))
							equal = false;
					equal;
				}
			case _: false;
		};
	}
}
