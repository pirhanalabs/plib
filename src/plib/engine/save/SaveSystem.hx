package plib.engine.save;

/** 
	Result of reading raw data from a storage backend. 
**/
enum SaveBackendRead
{
	Found(data:String);
	Missing;
	Failed(message:String);
}

/** 
	Result of a backend mutation. 
**/
enum SaveBackendWrite
{
	Success;
	Failed(message:String);
}

/** 
	Platform storage boundary. Projects may implement this for Steam or consoles. 
**/
interface SaveBackend
{
	/** 
		Reads the opaque key and completes exactly once with data, absence, or an error. 
	**/
	public function read(key:String, complete:SaveBackendRead->Void):Void;

	/** 
		Replaces a key safely and preserves its old value as `key + ".backup"` when possible. 
	**/
	public function writeAtomic(key:String, data:String, complete:SaveBackendWrite->Void):Void;

	/** 
		Deletes both the primary key and backend-managed recovery data. 
	**/
	public function delete(key:String, complete:SaveBackendWrite->Void):Void;
}

/** 
	Converts game-owned save data to and from JSON-compatible values. 
**/
interface SaveCodec<T>
{
	/** 
		Converts typed game state into JSON-compatible primitives, arrays, and objects. 
	**/
	public function encode(value:T):Dynamic;

	/** 
		Validates and reconstructs typed game state from a decoded JSON value. 
	**/
	public function decode(value:Dynamic):T;
}

/**
	Codec for small save formats that do not need a dedicated class.
	The encode function returns JSON-compatible data. The decode function must
	validate that data and reconstruct T, throwing when it is invalid.
	Errors are handled by SaveStore just like errors from other codecs.
**/
class BasicSaveCodec<T> implements SaveCodec<T>
{
	private final encoder:T->Dynamic;
	private final decoder:Dynamic->T;

	/** Creates a codec from encoding and validating decoding functions. **/
	public function new(encode:T->Dynamic, decode:Dynamic->T)
	{
		if (encode == null || decode == null)
			throw 'Save codecs require encode and decode functions.';
		encoder = encode;
		decoder = decode;
	}

	/** Converts typed state to JSON-compatible values using the supplied encoder. **/
	public inline function encode(value:T):Dynamic
		return encoder(value);

	/** Validates and reconstructs typed state using the supplied decoder. **/
	public inline function decode(value:Dynamic):T
		return decoder(value);
}

/** 
	Definition of one independently versioned collection of save slots. 
**/
typedef SaveDefinition<T> =
{
	var id:String;
	var version:Int;
	var codec:SaveCodec<T>;
	@:optional var migrate:(data:Dynamic, fromVersion:Int) -> Dynamic;
}

/** 
	User-facing load outcome. 
**/
enum SaveLoadResult<T>
{
	Loaded(value:T, recoveredFromBackup:Bool);
	Missing;
	UnsupportedVersion(savedVersion:Int, supportedVersion:Int);
	Corrupt(message:String);
	Failed(message:String);
}

/** 
	User-facing save and delete outcome. 
**/
enum SaveWriteResult
{
	Success;
	Failed(message:String);
}

/** 
	Read-only result-bearing operation that also supports asynchronous backends. 
**/
class SaveTask<T>
{
	/** 
		Completed result, or `null` while an asynchronous backend is pending. Prefer `onComplete`. 
	**/
	public var result(default, null):Null<T>;

	private var completeState:Bool;
	private final callbacks:Array<T->Void>;

	/** 
		Creates a pending result task; normally returned by a save operation. 
	**/
	public function new()
	{
		result = null;
		completeState = false;
		callbacks = [];
	}

	/** 
		Reports whether a result has been produced. 
	**/
	public inline function isComplete():Bool
		return completeState;

	/** 
		Observes the result once; runs immediately when the task already completed. 
	**/
	public function onComplete(callback:T->Void):SaveTask<T>
	{
		if (callback == null)
			throw 'Save completion callback cannot be null.';
		if (completeState)
			callback(cast result);
		else
			callbacks.push(callback);
		return this;
	}

	@:allow(plib.engine.save.SaveSystem)
	private function complete(value:T)
	{
		if (completeState)
			throw 'Save operation completed more than once.';
		result = value;
		completeState = true;
		var pending = callbacks.copy();
		callbacks.resize(0);
		for (callback in pending)
			callback(value);
	}
}

private typedef SaveEnvelope =
{
	var format:String;
	var version:Int;
	var timestamp:Float;
	var payload:Dynamic;
}

/** 
	Typed slot facade returned by `SaveSystem.define`. 
**/
class SaveStore<T>
{
	private static inline final FILE_HEADER = 'PLIB-SAVE-1';

	private final system:SaveSystem;
	private final definition:SaveDefinition<T>;

	@:allow(plib.engine.save.SaveSystem)
	private function new(system:SaveSystem, definition:SaveDefinition<T>)
	{
		this.system = system;
		this.definition = definition;
	}

	/** 
		Encodes and atomically writes `value` to a numbered slot. 
	**/
	public function save(slot:Int, value:T):SaveTask<SaveWriteResult>
	{
		if (slot < 0)
			throw 'Save slots cannot be negative.';
		var task = new SaveTask<SaveWriteResult>();
		var envelope:SaveEnvelope;
		try
		{
			envelope = {
				format: definition.id,
				version: definition.version,
				timestamp: Date.now().getTime(),
				payload: definition.codec.encode(value)
			};
		}
		catch (error)
		{
			task.complete(Failed('Could not encode save: ${Std.string(error)}'));
			return task;
		}

		var encoded:String;
		try
		{
			var json = haxe.Json.stringify(envelope);
			encoded = encodeFile(json);
		}
		catch (error)
		{
			task.complete(Failed('Could not serialize save: ${Std.string(error)}'));
			return task;
		}

		system.backend.writeAtomic(key(slot), encoded, result -> switch result
		{
			case Success: task.complete(Success);
			case Failed(message): task.complete(Failed(message));
		});
		return task;
	}

	/** 
		Loads, verifies, migrates, and decodes a slot, falling back to its backup. 
	**/
	public function load(slot:Int):SaveTask<SaveLoadResult<T>>
	{
		if (slot < 0)
			throw 'Save slots cannot be negative.';
		var task = new SaveTask<SaveLoadResult<T>>();
		loadKey(key(slot), false, task, null);
		return task;
	}

	private function loadKey(key:String, backup:Bool, task:SaveTask<SaveLoadResult<T>>, primaryFailure:Null<SaveLoadResult<T>>)
	{
		var actualKey = backup ? key + '.backup' : key;
		system.backend.read(actualKey, result -> switch result
		{
			case Found(data):
				var decoded = decode(data, backup);
				switch decoded
				{
					case Corrupt(_) if (!backup): loadKey(key, true, task, decoded);
					default: task.complete(decoded);
				}
			case Missing if (!backup): loadKey(key, true, task, Missing);
			case Missing: task.complete(primaryFailure == null ? Missing : primaryFailure);
			case Failed(message): task.complete(Failed(message));
		});
	}

	private function decode(encoded:String, backup:Bool):SaveLoadResult<T>
	{
		try
		{
			var envelope:SaveEnvelope = cast haxe.Json.parse(decodeFile(encoded));
			if (envelope == null || envelope.format != definition.id)
				return Corrupt('Save format does not match ${definition.id}.');
			if (!Std.isOfType(envelope.version, Int) || envelope.version <= 0)
				return Corrupt('Save version must be a positive integer.');
			if (envelope.version > definition.version)
				return UnsupportedVersion(envelope.version, definition.version);

			var payload = envelope.payload;
			if (envelope.version < definition.version)
			{
				if (definition.migrate == null)
					return UnsupportedVersion(envelope.version, definition.version);
				payload = definition.migrate(payload, envelope.version);
			}
			return Loaded(definition.codec.decode(payload), backup);
		}
		catch (error)
		{
			return Corrupt('Could not decode save: ${Std.string(error)}');
		}
	}

	/** 
		Wraps JSON in a small text envelope without Base64 or binary expansion. 
	**/
	private static function encodeFile(json:String):String
	{
		return FILE_HEADER + '\n' + haxe.crypto.Sha256.encode(json) + '\n' + json;
	}

	/** 
		Validates the exact stored JSON before parsing or invoking game codecs. 
	**/
	private static function decodeFile(encoded:String):String
	{
		if (encoded == null)
			throw 'Save data is empty.';
		var headerEnd = encoded.indexOf('\n');
		if (headerEnd < 0 || encoded.substr(0, headerEnd) != FILE_HEADER)
			throw 'Save header is missing or unsupported.';
		var checksumEnd = encoded.indexOf('\n', headerEnd + 1);
		if (checksumEnd < 0)
			throw 'Save checksum is missing.';
		var checksum = encoded.substring(headerEnd + 1, checksumEnd);
		if (checksum.length != 64)
			throw 'Save checksum has an invalid length.';
		var json = encoded.substr(checksumEnd + 1);
		if (haxe.crypto.Sha256.encode(json) != checksum)
			throw 'Save checksum does not match its contents.';
		return json;
	}

	/** 
		Permanently removes a slot and its backup. 
	**/
	public function delete(slot:Int):SaveTask<SaveWriteResult>
	{
		if (slot < 0)
			throw 'Save slots cannot be negative.';
		var task = new SaveTask<SaveWriteResult>();
		system.backend.delete(key(slot), result -> switch result
		{
			case Success: task.complete(Success);
			case Failed(message): task.complete(Failed(message));
		});
		return task;
	}

	private inline function key(slot:Int):String
		return definition.id + '/slot-' + slot;
}

/** 
	Application-owned save facade with automatic target backend selection. 

	Usage:

	1. Define the data you want to save in a typedef.
	```
	typedef GameSave = {
		var level:Int;
		var coins:Int;
	}
	```
	2. Write a codec to explain how to encode that data and how to recognize valid saved data.
	```
	class MyCodec implements plib.engine.save.SaveSystem.SaveCodec<GameSave>{
		public function new(){}

		public function encode(value:GameSave):Dynamic{
			return {
				level: value.level,
				coins: value.coins
			}	
		}

		public function decode(value:Dynamic):GameSave{
			// do data validation here
			return {
				level:value.level,
				coins: value.coins
			}	
		}
	}
	```

	3. Register a SaveStore somewhere in your application.

	```
	public var progress:plib.engine.save.SaveSystem.SaveStore<GameSave>
	```

	then initialize it in your application's `ready()` method:

	```
	progress = saves.define({
		id: "progress",
		version: 1,
		codec: new MyCodec()
	});
	```

	`"progress"` identifies this data family. You can define others as you want,
	each with its own slots and version. Register each id only once. `"settings"`
	is already reserved by `Application`.

	4. Save to a slot. Each save store has its own slots. Slot are integers that can
	represent anything you decide. 

	```
	progress.save(0, {
		level: 3,
		coins: 120,
	}).onComplete(result -> {
		switch(result){
			case Success:
				trace("game saved.");
			case Failed(message):
				trace("Save failed: " + message);
		}
	});
	```

	Saving to an existing slot replaces it and preserves the previous value as a backup
	when possible.

	5. Load a slot

	```
	progress.load(0).onComplete(result -> {
		switch(result){
			case Loaded(data, recovered):
				// apply the values to your game here.
				trace('Data loaded');
			case Missing:
				// Start a new game
				trace('No save exists.');
			case Corrupt(message):
				trace('Save data is invalid: $message');
			case UnsupportedVersion(savedVersion, supportedVersion):
				trace('Save version $savedVersion cannot be loaded by version $supportedVersion.');
			case Failed(message):
				trace('Storage could not be read: $message');
		}
	});
	```

	Loading returns data. It does not automatically restore your player, scenes, or other objects.

	##Settings##

	`app.settings` is a premade key/value store, so you don't need a codec.

	```
	var app = Application.get();

	// Load before reading preferences
	app.settings.load().onComplete(result -> {
		// handle your loaded settings here
		var volume = app.settings.get("musicVolume", 1.0);
	});

	// change a setting in memory only
	app.settings.set("musicVolume", 0.7);

	// persist the current settings
	app.settings.save().onComplete(result->{
		switch(result){
			case Success:
				trace("Settings Saved!");
			case Failed(message):
				trace("Oops! " + message);
		}
	});
	```

	When your save format changes, you can add a migration for older payloads.

	```
	progress = saves.define({
		id:'progress',
		version: 2,
		codec: new MyCodec(),
		migrate: (data, fromVersion)->{
			if (fromVersion == 1){
				data.lives = 3;	
			}

			return data;
		}
	});
	```

	Finally, you can use a basic codec for simplicity instead of creating a new one:

	```
	progress = saves.define({
		id:"progress",
		version: 1,
		codec: new plib.engine.save.SaveSystem.BasicSaveCodec<GameSave>(
			(value:GameSave)->{
				// encode here
				return {
					level: value.level,
					coins: value.coins,
				};
			},
			(data:Dynamic)->{
				// decode here
				return {
					level: data.level,
					coins: data.coins,
				}
			}
		);
	});
	```

	Storage is automatic. Browser builds use `localStorage`, native builds use files.


**/
class SaveSystem
{
	public final id:String;
	public final backend:SaveBackend;

	private final stores:Map<String, Dynamic>;

	/** 
		Creates a namespaced save facade using a caller-supplied backend. 
	**/
	public function new(id:String, backend:SaveBackend)
	{
		validateId(id, 'Save application');
		if (backend == null)
			throw 'SaveSystem requires a backend.';
		this.id = id;
		this.backend = backend;
		stores = [];
	}

	/** 
		Creates a system using browser storage on JS and files on native targets. 
	**/
	public static function createDefault(id:String):SaveSystem
	{
		return new SaveSystem(id, createDefaultBackend(id));
	}

	/** 
		Selects the standard platform backend. 
	**/
	public static function createDefaultBackend(id:String):SaveBackend
	{
		validateId(id, 'Save application');
		#if js
		return new BrowserSaveBackend(id);
		#elseif sys
		return new FileSaveBackend(id);
		#else
		return new UnsupportedSaveBackend();
		#end
	}

	/** 
		Creates isolated in-memory storage for tests and tools. 
	**/
	public static function memory(id:String = 'test'):SaveSystem
	{
		return new SaveSystem(id, new MemorySaveBackend());
	}

	/** 
		Registers one stable, versioned data family and returns its typed slot interface. 
	**/
	public function define<T>(definition:SaveDefinition<T>):SaveStore<T>
	{
		if (definition == null || definition.codec == null)
			throw 'Save definitions require an id and codec.';
		validateId(definition.id, 'Save definition');
		if (definition.version <= 0)
			throw 'Save definition versions must be positive.';
		if (stores.exists(definition.id))
			throw 'Save definition already exists: ${definition.id}';
		var store = new SaveStore<T>(this, definition);
		stores.set(definition.id, store);
		return store;
	}

	private static function validateId(value:String, label:String)
	{
		if (value == null || !~/^[A-Za-z0-9._-]+$/.match(value))
			throw '$label id may only contain letters, numbers, dot, underscore, and hyphen.';
	}
}

/** 
	Small persisted key/value store for framework and game preferences. 
**/
class SettingsStore
{
	private final store:SaveStore<Dynamic>;
	private var values:Dynamic;

	/** 
		Reserves the `settings` definition and stores all preferences in slot zero. 
	**/
	public function new(system:SaveSystem)
	{
		values = {};
		store = system.define({id: 'settings', version: 1, codec: new SettingsCodec()});
	}

	/** 
		Loads settings and replaces the current in-memory values when data exists. 
	**/
	public function load():SaveTask<SaveLoadResult<Dynamic>>
	{
		var task = store.load(0);
		task.onComplete(result -> switch result
		{
			case Loaded(loaded, _): values = loaded == null ? {} : loaded;
			default:
		});
		return task;
	}

	/** 
		Persists the current key/value snapshot. 
	**/
	public inline function save():SaveTask<SaveWriteResult>
		return store.save(0, values);

	/** 
		Returns a typed value or `fallback` when the key is absent. 
	**/
	public inline function get<T>(key:String, fallback:T):T
		return Reflect.hasField(values, key) ? cast Reflect.field(values, key) : fallback;

	/** 
		Reports whether a preference exists in memory. 
	**/
	public inline function has(key:String):Bool
		return Reflect.hasField(values, key);

	/** 
		Changes an in-memory preference and returns the assigned value. Call `save` to persist it. 
	**/
	public inline function set<T>(key:String, value:T):T
	{
		Reflect.setField(values, key, value);
		return value;
	}

	/** 
		Removes an in-memory preference. Call `save` to persist the removal. 
	**/
	public inline function remove(key:String):Bool
		return Reflect.deleteField(values, key);

	/** 
		Clears in-memory preferences without writing storage. 
	**/
	public function clear()
		values = {};
}

private class SettingsCodec implements SaveCodec<Dynamic>
{
	public function new() {}

	public inline function encode(value:Dynamic):Dynamic
		return value;

	public function decode(value:Dynamic):Dynamic
	{
		if (value == null || !Reflect.isObject(value))
			throw 'Settings payload must be an object.';
		return value;
	}
}

/** 
	In-memory backend intended for deterministic tests and tools. 
**/
class MemorySaveBackend implements SaveBackend
{
	public final values:Map<String, String> = [];

	public function new() {}

	public function read(key:String, complete:SaveBackendRead->Void)
	{
		complete(values.exists(key) ? Found(values.get(key)) : Missing);
	}

	public function writeAtomic(key:String, data:String, complete:SaveBackendWrite->Void)
	{
		if (values.exists(key))
			values.set(key + '.backup', values.get(key));
		values.set(key, data);
		complete(Success);
	}

	public function delete(key:String, complete:SaveBackendWrite->Void)
	{
		values.remove(key);
		values.remove(key + '.backup');
		complete(Success);
	}
}

#if js
private class BrowserSaveBackend implements SaveBackend
{
	private final prefix:String;

	public function new(id:String)
		prefix = id + ':';

	public function read(key:String, complete:SaveBackendRead->Void)
	{
		try
		{
			var value = js.Browser.window.localStorage.getItem(prefix + key);
			complete(value == null ? Missing : Found(value));
		}
		catch (error)
			complete(Failed(Std.string(error)));
	}

	public function writeAtomic(key:String, data:String, complete:SaveBackendWrite->Void)
	{
		try
		{
			var storage = js.Browser.window.localStorage;
			var primary = prefix + key;
			var temporary = primary + '.temporary';
			storage.setItem(temporary, data);
			var previous = storage.getItem(primary);
			if (previous != null)
				storage.setItem(primary + '.backup', previous);
			storage.setItem(primary, data);
			storage.removeItem(temporary);
			complete(Success);
		}
		catch (error)
			complete(Failed(Std.string(error)));
	}

	public function delete(key:String, complete:SaveBackendWrite->Void)
	{
		try
		{
			var primary = prefix + key;
			js.Browser.window.localStorage.removeItem(primary);
			js.Browser.window.localStorage.removeItem(primary + '.backup');
			js.Browser.window.localStorage.removeItem(primary + '.temporary');
			complete(Success);
		}
		catch (error)
			complete(Failed(Std.string(error)));
	}
}
#end

#if sys
private class FileSaveBackend implements SaveBackend
{
	private final root:String;

	public function new(id:String)
	{
		var home = Sys.getEnv('HOME');
		var system = Sys.systemName();
		if (system == 'Windows')
		{
			var appData = Sys.getEnv('APPDATA');
			root = haxe.io.Path.join([appData == null ? '.' : appData, id]);
		}
		else if (system == 'Mac')
			root = haxe.io.Path.join([home == null ? '.' : home, 'Library', 'Application Support', id]);
		else
		{
			var dataHome = Sys.getEnv('XDG_DATA_HOME');
			root = dataHome != null ? haxe.io.Path.join([dataHome, id]) : haxe.io.Path.join([home == null ? '.' : home, '.local', 'share', id]);
		}
	}

	public function read(key:String, complete:SaveBackendRead->Void)
	{
		var path = resolve(key);
		if (!sys.FileSystem.exists(path))
		{
			complete(Missing);
			return;
		}
		try
			complete(Found(sys.io.File.getContent(path)))
		catch (error)
			complete(Failed(Std.string(error)));
	}

	public function writeAtomic(key:String, data:String, complete:SaveBackendWrite->Void)
	{
		var primary = resolve(key);
		var temporary = primary + '.temporary';
		var backup = resolve(key + '.backup');
		try
		{
			ensureDirectory(haxe.io.Path.directory(primary));
			sys.io.File.saveContent(temporary, data);
			if (sys.FileSystem.exists(backup))
				sys.FileSystem.deleteFile(backup);
			if (sys.FileSystem.exists(primary))
				sys.FileSystem.rename(primary, backup);
			sys.FileSystem.rename(temporary, primary);
			complete(Success);
		}
		catch (error)
		{
			try
				if (sys.FileSystem.exists(temporary))
					sys.FileSystem.deleteFile(temporary)
			catch (_) {}
			complete(Failed(Std.string(error)));
		}
	}

	public function delete(key:String, complete:SaveBackendWrite->Void)
	{
		var primary = resolve(key);
		try
		{
			for (path in [primary, resolve(key + '.backup'), primary + '.temporary'])
				if (sys.FileSystem.exists(path))
					sys.FileSystem.deleteFile(path);
			complete(Success);
		}
		catch (error)
			complete(Failed(Std.string(error)));
	}

	private inline function resolve(key:String):String
		return haxe.io.Path.join([root, key + '.save']);

	private static function ensureDirectory(path:String)
	{
		if (path == null || path.length == 0 || sys.FileSystem.exists(path))
			return;
		var parent = haxe.io.Path.directory(path);
		if (parent != path)
			ensureDirectory(parent);
		if (!sys.FileSystem.exists(path))
			sys.FileSystem.createDirectory(path);
	}
}
#end

private class UnsupportedSaveBackend implements SaveBackend
{
	public function new() {}

	private inline function message()
		return 'No default save backend exists for this target.';

	public function read(key:String, complete:SaveBackendRead->Void)
		complete(Failed(message()));

	public function writeAtomic(key:String, data:String, complete:SaveBackendWrite->Void)
		complete(Failed(message()));

	public function delete(key:String, complete:SaveBackendWrite->Void)
		complete(Failed(message()));
}
