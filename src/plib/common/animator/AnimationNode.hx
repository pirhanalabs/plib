package plib.common.animator;

class AnimationNode<T> extends AnimatorNode
{
	var o:T;
	var timeCur:Float;
	var timeMax:Float;
	var fn:Float->T->Void;
	var cb:T->Void;
	var _isComplete:Bool;

	public function new(stime:Float, o:T, fn:Float->T->Void)
	{
		super();
		timeCur = 0;
		timeMax = stime;

		_isComplete = false;

		this.o = o;
		this.fn = fn;
	}

	public function done(cb:T->Void)
	{
		this.cb = cb;
	}

	override function update(frame:plib.engine.Frame)
	{
		if (timeCur == timeMax)
		{
			_isComplete = true;
			return;
		}

		timeCur += frame.dt;

		if (timeCur > timeMax)
		{
			timeCur = timeMax;
		}
	}

	override function postupdate()
	{
		if (_isComplete)
		{
			return;
		}

		if (fn != null)
		{
			fn(timeCur / timeMax, o);
		}
	}

	override function isComplete():Bool
	{
		return timeCur >= timeMax;
	}

	override function callback()
	{
		if (cb != null)
		{
			cb(o);
		}
	}
}
