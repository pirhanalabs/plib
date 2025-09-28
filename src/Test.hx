import plib.MathTools;
import plib.engine.Application;
import plib.engine.Frame;

using plib.core.extensions.ArrayExtension;
using plib.core.extensions.IterableExtension;

class TestScreen extends plib.engine.Screen
{
	var obj:h2d.Bitmap;
	var velx:Float = 1;
	var vely:Float = 1.5;

	public function new()
	{
		super();

		trace('iterable test 1: ' + [0, 0, 0, 1].every(n -> n == 0));
		trace('iterable test 2: ' + [0, 0, 0, 0].every(n -> n == 0));
		trace('reduce test: ' + [1, 2, 3, 4].reduce((acc, n) -> acc + n, 0));
		trace('totalize test: ' + [1, 2, 3, 4].totalize());
		trace('average test: ' + [1, 2, 3, 4].average());
	}

	override function ready()
	{
		super.ready();

		obj = new h2d.Bitmap(h2d.Tile.fromColor(0xffa500, 16, 16));
		root.add(obj, 1);
	}

	private function handleInputs()
	{
		if (hxd.Key.isPressed(hxd.Key.SPACE))
		{
			camera.bump(0, -10);
			camera.shake(0.1, 2);
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
		pushScreen(new TestScreen());
	}
}
