import plib.MathTools;
import plib.engine.Application;
import plib.engine.Frame;

using plib.common.extensions.ArrayExtension;
using plib.common.extensions.IterableExtension;

enum InputID
{
	Interact;
	Cancel;
	Settings;
	Start;
	MoveUp;
	MoveDw;
	MoveRt;
	MoveLt;
}

class Inputs
{
	public static var controller:plib.engine.InputController<InputID>;

	public static function Init()
	{
		controller = new plib.engine.InputController(plib.engine.Application.get().inputs);
		controller.registerInput(Interact, A, hxd.Key.SPACE, null);
		controller.registerInput(Cancel, B, hxd.Key.ESCAPE, null);
		controller.registerInput(Settings, SELECT, hxd.Key.ESCAPE, null);
		controller.registerInput(Start, START, hxd.Key.SHIFT, null);
		controller.registerInput(MoveUp, DPAD_UP, hxd.Key.W, plib.Direction.N);
		controller.registerInput(MoveLt, DPAD_LEFT, hxd.Key.A, plib.Direction.W);
		controller.registerInput(MoveDw, DPAD_DOWN, hxd.Key.S, plib.Direction.S);
		controller.registerInput(MoveRt, DPAD_RIGHT, hxd.Key.D, plib.Direction.E);
	}

	public static function getString(id:InputID)
	{
		return controller.get(id).getName();
	}
}

typedef ControllerAccess = plib.engine.InputControllerAccess<InputID>;

class TestNavItem extends plib.heaps.nav.BasicNavigationInstance
{
	var g:h2d.Bitmap;
	var t1 = h2d.Tile.fromColor(0xffa500, 16, 16);
	var t2 = h2d.Tile.fromColor(0x00ff00, 16, 16);

	public function new()
	{
		super();

		g = new h2d.Bitmap(t1, this);
	}

	override function focus()
	{
		super.focus();
		g.tile = t2;
		trace('focused');
	}

	override function unfocus()
	{
		super.unfocus();
		g.tile = t1;
		trace('unfocused');
	}

	override function execute()
	{
		super.execute();
		trace('executed!');
	}
}

class TestScreen extends plib.engine.Screen
{
	var obj:h2d.Bitmap;
	var velx:Float = 1;
	var vely:Float = 1.5;

	var nav = new plib.heaps.nav.NavigationManager();
	var ca:ControllerAccess;

	public function new()
	{
		super();

		trace('test random sign:' + MathTools.randsign());

		trace('iterable test 1: ' + [0, 0, 0, 1].every(n -> n == 0));
		trace('iterable test 2: ' + [0, 0, 0, 0].every(n -> n == 0));
		trace('reduce test: ' + [1, 2, 3, 4].reduce((acc, n) -> acc + n, 0));
		trace('totalize test: ' + [1, 2, 3, 4].totalize());
		trace('average test: ' + [1, 2, 3, 4].average());

		trace('exact test 1: ' + [1, 2, 3, 4].exact(1, m -> m == 1));
		trace('exact test 2: ' + [1, 2, 3, 4].exact(1, m -> m == 5));
		trace('some test: ' + [1, 2, 3, 4].some(2, m -> m < 3));
		trace('some test: ' + [1, 2, 3, 4].some(2, m -> m <= 3));
		trace('some test: ' + [1, 2, 3, 4].some(2, m -> m < 2));
		trace('any test: ' + [1, 2, 3, 4].any(m -> m == 4));
		trace('any test: ' + [1, 2, 3, 4].any(m -> m == 5));

		trace('max element test: ' + [1, 2, 3, 4].getMaxElement(m -> m));
		trace('max value test: ' + [1, 2, 3, 4].getMaxValue(m -> m));
		trace('min element test: ' + [1, 2, 3, 4].getMinElement(m -> m));
		trace('min value test: ' + [1, 2, 3, 4].getMinValue(m -> m));

		trace('overload 1:', [1, 2, 3, 4].totalize());
		trace('overload 2:', [1, 2, 3, 4].totalize((r) -> r / 2));

	}

	override function ready()
	{
		super.ready();

		ca = Inputs.controller.createAccess();
		ca.grantAccess();

		obj = new h2d.Bitmap(h2d.Tile.fromColor(0xffa500, 16, 16));
		root.add(obj, 1);

		var options = [new TestNavItem(), new TestNavItem(), new TestNavItem(), new TestNavItem(),];

		for (i in 0...options.length)
		{
			var o = options[i];
			root.add(o, 2);

			o.x = app.vw2 + MathTools.layout(20, options.length, i) - 10;
			nav.add(o);
		}

		plib.heaps.nav.NavigationHelper.buildLinear(nav, Dw, options);

		nav.select(options[0]);
	}

	function handleInputs()
	{
		if (ca.pressed(Interact))
		{
			camera.bump(0, -10);
			camera.shake(0.1, 2);
		}

		// navigation
		if (ca.pressed(MoveLt))
		{
			nav.tryMove(Lt);
		}
		else if (ca.pressed(MoveRt))
		{
			nav.tryMove(Rt);
		}
		else if (ca.pressed(MoveDw))
		{
			nav.tryMove(Dw);
			trace('working?');
		}
		else if (ca.pressed(MoveUp))
		{
			nav.tryMove(Up);
			trace('working?');
		}
	}

	override function update(frame:Frame)
	{
		super.update(frame);

		handleInputs();

		obj.x += velx * frame.tmod;
		obj.y += vely * frame.tmod;
		obj.y += Math.cos(frame.elapsed * 4) * 2;
		obj.x += Math.cos(frame.elapsed * 2) * 2;

		// collision checks
		if (obj.x < 0)
		{
			obj.x = 0;
			velx = -velx;
		}
		else if (obj.x >= app.vw - obj.tile.width)
		{
			obj.x = app.vw - obj.tile.width;
			velx = -velx;
		}

		if (obj.y < 0)
		{
			obj.y = 0;
			vely = -vely;
		}
		else if (obj.y >= app.vh - obj.tile.height)
		{
			obj.y = app.vh - obj.tile.height;
			vely = -vely;
		}
	}

	private function inbounds(obj:h2d.Object)
	{
		return obj.x >= 0 && obj.y >= 0 && obj.x < app.vw && obj.y < app.vh;
	}

	override function postupdate()
	{
		super.postupdate();
	}
}

class Test extends Application
{
	public static function main()
	{
		new Test(600, 300);
	}

	override function ready()
	{
		super.ready();
		engine.backgroundColor = 0xff0000;
		Inputs.Init();
		pushScreen(new TestScreen());
	}
}
