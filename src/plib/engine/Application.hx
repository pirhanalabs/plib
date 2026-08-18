package plib.engine;

import hxd.Window;
import plib.engine.input.InputSystem;
import plib.engine.nodes.LayerNode;
import plib.engine.nodes.LayersGroupNode.ViewportBorderMode;
import plib.engine.nodes.LayersGroupNode;
import plib.engine.nodes.NodeTree.RootNode;
import plib.engine.nodes.NodeTree;
import plib.engine.nodes.ScreenManager;
import plib.engine.save.SaveSystem;
import plib.engine.save.SaveSystem.SaveBackend;
import plib.engine.save.SaveSystem.SettingsStore;

/** Standard plib/Heaps bootstrap owning timing, input, persistence, tree, layers, and screens. **/
class Application extends hxd.App
{
	private static var instance:Application;

	/**
		Static instance getter.
	**/
	public static function get()
	{
		return instance;
	}

	private final referenceWidth:Int;
	private final referenceHeight:Int;
	private final initialIntegerScaling:Bool;
	private final saveId:String;

	/** Automatically created logical root, tree, and presentation layers. **/
	public var root(default, null):RootNode;

	public var tree(default, null):NodeTree;
	public var layers(default, null):LayersGroupNode;
	public var world(get, never):LayerNode;
	public var hud(get, never):LayerNode;
	public var windowLayer(get, never):LayerNode;

	/** Default main screen stack mounted in the fitted content layer. **/
	public var screens(default, null):ScreenManager;

	/** Modal stack mounted in the HUD overlay. **/
	public var modals(default, null):ScreenManager;

	/** Application-owned input sampler and local player/session facade. **/
	public var inputs(default, null):InputSystem;
	/** Persistent game saves and the standard preferences store. **/
	public var saves(default, null):SaveSystem;
	public var settings(default, null):SettingsStore;

	/** window api **/
	public var window(default, null):Window;

	/** frame information **/
	public var frame(default, null):Frame;

	/** Creates the app with a logical world resolution and stable optional persistence namespace. **/
	public function new(referenceWidth:Int, referenceHeight:Int, integerScaling:Bool, ?saveId:String)
	{
		if (instance != null)
			throw 'Only one Application instance can exist.';
		if (referenceWidth <= 0 || referenceHeight <= 0)
			throw 'Application reference dimensions must be positive.';

		super();
		instance = this;
		this.referenceWidth = referenceWidth;
		this.referenceHeight = referenceHeight;
		this.initialIntegerScaling = integerScaling;
		this.saveId = saveId == null ? defaultSaveId() : saveId;
	}

	override function init()
	{
		super.init();

		window = hxd.Window.getInstance();
		frame = new Frame();
		saves = new SaveSystem(saveId, createSaveBackend(saveId));
		settings = new SettingsStore(saves);
		root = new RootNode();
		inputs = root.add(InputSystem.createForHeaps(window));
		layers = root.add(new LayersGroupNode(referenceWidth, referenceHeight, initialIntegerScaling));
		screens = layers.world.content.add(createScreenManager());
		modals = layers.hud.overlay.add(createScreenManager());
		modals.blocks(screens);
		tree = new NodeTree(root, s2d, this);

		initializeEngine();

		#if (sys || js)
		hxd.Window.getInstance().onClose = () ->
		{
			dispose();
			return true;
		};
		#end

		onResize();
		haxe.Timer.delay(ready, 1);
	}

	private inline function get_world():LayerNode
		return layers.world;

	private inline function get_hud():LayerNode
		return layers.hud;

	private inline function get_windowLayer():LayerNode
		return layers.window;

	/** Factory hook used for the application's primary and modal screen stacks. **/
	private function createScreenManager():ScreenManager
	{
		return new ScreenManager();
	}

	/** Override for Steam Cloud, console storage, or another project-specific backend. **/
	private function createSaveBackend(id:String):SaveBackend
	{
		return SaveSystem.createDefaultBackend(id);
	}

	private function defaultSaveId():String
	{
		var name = Type.getClassName(Type.getClass(this));
		if (name == null) return 'plib-game';
		return ~/[^A-Za-z0-9._-]/g.replace(name, '-');
	}

	private function initializeEngine()
	{
		engine.backgroundColor = 0x000000;
		haxe.MainLoop.add(() -> {}); // sound fix, do not remove
		hxd.snd.Manager.get();
		hxd.Timer.skip();
		hxd.Timer.smoothFactor = 0.4;
		hxd.Timer.wantedFPS = 60;

		#if hl
		hl.UI.closeConsole();
		hl.Api.setErrorHandler(onCrash);
		#end
	}

	private function ready() {}

	#if hl
	private function onCrash(error:Dynamic)
	{
		var title = 'Fatal Error';
		var msg = "I'm very sorry! The game crashed. Error:\n\n" + Std.string(error);

		var flags:haxe.EnumFlags<hl.UI.DialogFlags> = new haxe.EnumFlags();
		flags.set(IsError);

		var log = [Std.string(error)];

		try
		{
			log.push('Exception:');
			log.push(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
			log.push('Callstack:');
			log.push(haxe.CallStack.toString(haxe.CallStack.callStack()));

			sys.io.File.saveContent("crash.log", log.join("\n"));
			hl.UI.dialog(title, msg, flags);
		}
		catch (e)
		{
			sys.io.File.saveContent("crash2.log", log.join("\n"));
			hl.UI.dialog(title, msg, flags);
		}
		hxd.System.exit();
	}
	#end

	// ---- helpers ----

	/** Selects empty viewport margins or solid physical-window bands. **/
	public inline function setBorderMode(mode:ViewportBorderMode)
	{
		layers.setBorderMode(mode);
	}

	/** Enables or disables integer fitting and reapplies presentation layout. **/
	public function setIntegerScaling(enabled:Bool)
	{
		world.setIntegerScaling(enabled);
	}

	/**
		Maximize the window context.
	**/
	public function maximizeWindow()
	{
		#if (hlsdl || hldx)
		@:privateAccess window.window.maximize();
		#end
	}

	/**
		Sets the position of the window.
	**/
	public function setWindowPosition(x:Int, y:Int)
	{
		#if (hlsdl || hldx)
		@:privateAccess window.window.setPosition(x, y);
		#end
	}

	// ---- processing ----

	override function onResize()
	{
		super.onResize();
		if (layers == null)
			return;

		var currentWindow = window == null ? hxd.Window.getInstance() : window;
		layers.resize(currentWindow.width, currentWindow.height);
		if (tree != null)
			tree.resize();
	}

	override function update(dt:Float)
	{
		super.update(dt);

		frame.update();
		inputs.updateState(frame.dt);
		tree.process(frame);
	}
}
