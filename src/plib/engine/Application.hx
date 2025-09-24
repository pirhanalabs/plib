package plib.engine;

class Application extends hxd.App
{
	private static var instance:Application;

	public static function get()
	{
		if (Application.instance == null)
			throw 'application not created yet.';
		return Application.instance;
	}

	// accessors
	public var window(default, null):hxd.Window;
	public var frame(default, null):plib.engine.Frame;
	public var cursor(default, null):plib.engine.CustomCursor;
	public var inputs(default, null):plib.engine.InputManager;

	public var vw(default, null):Int;
	public var vh(default, null):Int;
	public var vw2(default, null):Float;
	public var vh2(default, null):Float;

	private var ox(default, null):Float;
	private var oy(default, null):Float;

	private var vs:Float;
	private var integerScaling:Bool;

	// borders
	private var hasBorders:Bool;
	private var bordersInvalidated:Bool;
	private var borders:h2d.Graphics;

	// layers
	private var backgroundLayer:h2d.Object;
	private var screenLayer:h2d.Object;
	private var uiLayer:h2d.Object;
	private var overlayLayer:h2d.Layers;
	private var screenShaderLayer:h2d.Object; // between screen/overlay/background and overlay layer

	// screen management
	private var screens:Array<Screen>;
	private var screenCount:Int;

	private var globalMouseX(get, never):Int;
	private var globalMouseY(get, never):Int;

	private function new(vw:Int, vh:Int)
	{
		super();
		Application.instance = this;
		this.vw = vw;
		this.vh = vh;
		this.vw2 = vw * 0.5;
		this.vh2 = vh * 0.5;
		this.vs = 1;
		this.ox = 0;
		this.oy = 0;

		bordersInvalidated = false;
		integerScaling = true;
		hasBorders = true;

		screens = [];
		screenCount = 0;
	}

	override function init()
	{
		super.init();
		__initEngine();
		__initLayers();
		__initEvents();
		__initSystems();
		__initBorders();

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

	/** override this for game initialization in boot class. **/
	private function ready() {}

	@:noCompletion
	private function __initSystems()
	{
		this.window = hxd.Window.getInstance();
		this.frame = new plib.engine.Frame();

		this.cursor = new plib.engine.CustomCursor();
		overlayLayer.add(this.cursor.cursor, 2);
		this.cursor.setCursorPosition(window.mouseX, window.mouseY);

		this.inputs = new plib.engine.InputManager();
	}

	@:noCompletion
	private function __initLayers()
	{
		screenShaderLayer = new h2d.Object();
		backgroundLayer = new h2d.Object(screenShaderLayer);
		screenLayer = new h2d.Object(screenShaderLayer);
		uiLayer = new h2d.Object(screenShaderLayer);
		overlayLayer = new h2d.Layers();

		s2d.add(screenShaderLayer, 0);
		s2d.add(overlayLayer, 2);
	}

	@:noCompletion
	private function __initBorders()
	{
		borders = new h2d.Graphics();
		borders.beginFill(0x000000, 1);
		borders.drawRect(-vw, -vh * 0.5, vw, vh * 2); // left
		borders.drawRect(-vw * 0.5, -vh, vw * 2, vh); // top
		borders.drawRect(vw, -vh * 0.5, vw, vh * 2); // right
		borders.drawRect(-vw * 0.5, vh, vw * 2, vh); // bottom
		s2d.add(borders, 1);
		bordersInvalidated = true;
	}

	@:noCompletion
	private function __initEvents()
	{
		this.s2d.addEventListener(function(e:hxd.Event)
		{
			switch (e.kind)
			{
				case EPush:
				case ERelease:
				case EMove:
				case EOver:
				case EOut:
				case EWheel:
				case EFocus:
				case EFocusLost:
				case EKeyDown:
				case EKeyUp:
				case EReleaseOutside:
				case ETextInput:
				case ECheck:
			}
		});
	}

	override function update(dt:Float)
	{
		super.update(dt);
		_update(dt);
		_postupdate();
	}

	override function onResize()
	{
		super.onResize();
		vs = hxd.Math.min(window.width / vw, window.height / vh);
		vs = integerScaling ? Std.int(vs) : vs;
		ox = (window.width - vw * vs) * 0.5;
		oy = (window.height - vh * vs) * 0.5;
		bordersInvalidated = true;
	}

	private function _update(dt:Float)
	{
		frame.update();
		cursor.setCursorPosition(window.mouseX, window.mouseY);
		cursor.update(frame);
		inputs.update(frame);

		if (screenCount > 0)
		{
			screens[screenCount - 1].__update(frame);
		}
	}

	private function _postupdate()
	{
		cursor.postupdate();

		if (screenCount > 0)
		{
			screens[screenCount - 1].__postupdate();
		}

		if (bordersInvalidated)
		{
			backgroundLayer.x = ox;
			backgroundLayer.y = oy;
			backgroundLayer.setScale(vs);

			screenLayer.x = ox;
			screenLayer.y = oy;
			screenLayer.setScale(vs);

			uiLayer.x = ox;
			uiLayer.y = oy;
			uiLayer.setScale(vs); // maybe not this?

			borders.x = ox;
			borders.y = oy;
			borders.setScale(vs);

			borders.visible = hasBorders;
			bordersInvalidated = false;

			// update other things that need updating when the scale changed
			cursor.onResize(vs);

			if (screenCount > 0)
			{
				screens[screenCount - 1].resize();
			}
		}
	}

	@:noCompletion
	private function __initEngine()
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

	public function maximizeWindow()
	{
		#if (hlsdl || hldx)
		@:privateAccess window.window.maximize();
		#end
	}

	public function setWindowPosition(x:Int, y:Int)
	{
		#if (hlsdl || hldx)
		@:privateAccess window.window.setPosition(x, y);
		#end
	}

	public function pushScreen(screen:Screen):Void
	{
		if (screenCount > 0)
		{
			getCurrentScreen().unfocus();
		}
		screens.push(screen);
		screenCount++;

		screen.__init(this);
		screenLayer.addChild(screen.camera.ob1);
		screen.ready();
	}

	public function popScreen():Screen
	{
		if (screenCount == 0)
			return null;

		var screen = screens.pop();
		screen.root.remove();
		screen.dispose();
		screenCount--;

		if (screenCount > 0)
		{
			getCurrentScreen().focus();
		}
		return screen;
	}

	inline function getCurrentScreen()
	{
		return screens[screenCount - 1];
	}

	inline function get_globalMouseX()
	{
		return Std.int(s2d.mouseX);
	}

	inline function get_globalMouseY()
	{
		return Std.int(s2d.mouseY);
	}
}
