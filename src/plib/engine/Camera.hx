package plib.engine;

class Camera
{
	@:allow(plib.engine.Application)
	var ob1:h2d.Object; // camera container
	var ob2:h2d.Object; // camera object
	var ob3:h2d.Object; // root repositioner

	var ob1x:Float;
	var ob1y:Float;
	var ob2x:Float;
	var ob2y:Float;
	var ob3x:Float;
	var ob3y:Float;
	var needRepositioning:Bool;

	var shakeTime:Float = 0.0;
	var shakeTimeMax:Float = 0.0;

	public var shakeStrength:Float = 2.0;

	/**
		A camera system that affects its `ctx`.
	**/
	public function new(ctx:h2d.Object)
	{
		ob1 = new h2d.Object();
		ob2 = new h2d.Object(ob1);
		ob3 = new h2d.Object(ob2);
		ob3.addChild(ctx);

		ob1x = 0;
		ob1y = 0;
		ob2x = 0;
		ob2y = 0;
		ob3x = 0;
		ob3y = 0;
		needRepositioning = true;
	}

	public function setViewport(vw:Int, vh:Int)
	{
		ob1x = vw * 0.5;
		ob1y = vh * 0.5;
		ob3x = -ob1x;
		ob3y = -ob1y;
		needRepositioning = true;
	}

	public function shake(seconds:Float)
	{
		if (this.shakeTime > seconds)
			return;

		this.shakeTime = seconds;
		this.shakeTimeMax = seconds;
	}

	public function update(frame:plib.engine.Frame)
	{
		ob2x = 0;

		if (shakeTime > 0)
		{
			shakeTime -= frame.dt;
			ob2x = MathTools.sign(Math.sin(frame.frames) * 30 * frame.tmod) * shakeStrength * shakeTime / shakeTimeMax;
		}
	}

	public function postupdate()
	{
		if (needRepositioning)
		{
			ob1.x = ob1x;
			ob1.y = ob1y;
			ob2.x = ob2x;
			ob2.y = ob2y;
			ob3.x = ob3x;
			ob3.y = ob3y;
			needRepositioning = false;
		}

		
		ob2.x = ob2x;
		ob2.y = ob2y;
		
	}
}
