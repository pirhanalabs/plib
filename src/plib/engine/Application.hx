package plib.engine;

import hxd.Window;
import plib.engine.input.InputSystem;
import plib.engine.nodes.LayerNode;
import plib.engine.nodes.LayersGroupNode.ViewportBorderMode;
import plib.engine.nodes.LayersGroupNode;
import plib.engine.nodes.NodeTree.RootNode;
import plib.engine.nodes.NodeTree;
import plib.engine.nodes.ScreenManager;
import plib.engine.save.SaveSystem.SaveBackend;
import plib.engine.save.SaveSystem.SettingsStore;
import plib.engine.save.SaveSystem;

/**
	Application entry point.

	The plib framework works using a node tree hierarchy inspired by Godot.

	The project architecture should use nodes when things need updating or
	the graphical hierarchy, like screens, objects, systems, etc.

	To start a new project, extend this class. Creating a new application
	instance requires to give a viewport width, viewport height, and set the integerScaling mode.
	You may also give a save id, which the save system will use.

	Add new NodeScreen using the `screens` manager. 
	The common methods are `push(screen)`, `pop()`, `replace(screen)` and `change(screen)`.
	Push adds a screen to the top of the stack, pop removes the top screen of the stack, replace does both at
	once, and change removes all previous screens and sets the new one.
**/
class Application extends hxd.App
{
	// ---- static instance ----
	private static var instance:Application;

	public static function get()
	{
		return instance;
	}

	/**
		Top node of the tree hierarchy. This should
		rarely ever be used for general purpose uses.
	**/
	public var root(default, null):RootNode;

	/**
		Manages the node hierarchy rooted at `root`.
		Runs callbacks and handle node lifecycle.

		Changes requested during updates are queued and processed
		after them.
	**/
	public var tree(default, null):NodeTree;

	/**
		Contains and manage the screen layers and how they are handled.
		Each layer have its own viewport property that can be
		independantly changed. This contains the `hudLayer`, `worldLayer` and `windowLayer`.
	**/
	public var layers(default, null):LayersGroupNode;

	public var hudLayer(get, never):LayerNode;
	public var worldLayer(get, never):LayerNode;
	public var windowLayer(get, never):LayerNode;

	/** 
		Default main screen stack mounted in the fitted content layer. 
	**/
	public var screens(default, null):ScreenManager;

	/** 
		Modal stack mounted in the HUD overlay. 
	**/
	public var modals(default, null):ScreenManager;

	/** 
		Application-owned input sampler and local player/session facade. 
	**/
	public var inputs(default, null):InputSystem;

	/** 
		Persistent game save data. Handles sys and js. 
	**/
	public var saves(default, null):SaveSystem;

	/**
		Player preference store.
	**/
	public var settings(default, null):SettingsStore;

	/** 
		Reference to the window api.
	**/
	public var window(default, null):Window;

	/** 
		Frame information, like tmod, dt, elapsed, frames.
	**/
	public var frame(default, null):Frame;

	/** 
		Creates the app with a viewport resolution and stable optional persistence namespace. 
	**/
	public function new(viewportWid:Int, viewportHei:Int, integerScaling:Bool, ?saveId:String)
	{
		if (instance != null)
			throw 'Only one Application instance can exist.';
		if (viewportWid <= 0 || viewportHei <= 0)
			throw 'Application reference dimensions must be positive.';

		super();
		instance = this;

		this.layers = new LayersGroupNode(viewportWid, viewportHei, integerScaling);

		var sid = makeSaveId(saveId);
		this.saves = new SaveSystem(sid, createSaveBackend(sid));
	}

	/**
		Utility function to create a save id name.
	**/
	private inline function makeSaveId(id:Null<String>)
	{
		return id == null ? defaultSaveId() : id;
	}

	/**
		Initialize everything necessary for the application to function.
	**/
	override final function init()
	{
		super.init();

		window = hxd.Window.getInstance();
		frame = new Frame();
		settings = new SettingsStore(saves);
		root = new RootNode();
		inputs = root.add(InputSystem.createForHeaps(window));
		root.add(layers);
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

	private inline function get_worldLayer():LayerNode
		return layers.world;

	private inline function get_hudLayer():LayerNode
		return layers.hud;

	private inline function get_windowLayer():LayerNode
		return layers.window;

	/** 
		Factory hook used for the application's primary and modal screen stacks. 
	**/
	private function createScreenManager():ScreenManager
	{
		return new ScreenManager();
	}

	/** 
		Override for Steam Cloud, console storage, or another project-specific backend. 
	**/
	private function createSaveBackend(id:String):SaveBackend
	{
		return SaveSystem.createDefaultBackend(id);
	}

	/**
		Override this to change the default save id, although
		you can simply give a save id name to the application directly
		in the constructor.
	**/
	private function defaultSaveId():String
	{
		var name = Type.getClassName(Type.getClass(this));
		if (name == null)
			return 'plib-game';
		return ~/[^A-Za-z0-9._-]/g.replace(name, '-');
	}

	/**
		Initializes the heaps engine properly
		and fixes the sound bug. Nothing of this should
		be changed or skipped if overridden.
	**/
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

	/**
		Override this to add behavior once every
		part of the application is ready. this triggers
		after `loadAssets` and 'init`.
	**/
	private function ready() {}

	/**
		Handles the crash errors.
	**/
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

	/** 
		Selects empty viewport margins or solid physical-window bands. 
	**/
	public inline function setBorderMode(mode:ViewportBorderMode)
	{
		layers.setBorderMode(mode);
	}

	/** 
		Enables or disables integer fitting and reapplies presentation layout. 
	**/
	public function setIntegerScaling(enabled:Bool)
	{
		worldLayer.setIntegerScaling(enabled);
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
