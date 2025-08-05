package core.heaps.animator;

class AnimatorController<T:h2d.Object> implements IAnimatorController implements engine.IUpdateable
{
	public var animationType(default, set):AnimatorType;

	inline function set_animationType(val:AnimatorType)
	{
		if (animationType == PingPong && val != PingPong)
		{
			dir = 1;
		}
		animationType = val;
		return animationType;
	}

	public var destroyed(default, null):Bool;

	private var dir:Int;
	private var target:T;
	private var timer:Float;
	private var queueIndex:Int;
	private var queue:Array<IAnimatorAction>;
	private var current:Null<IAnimatorAction>;

	public function new(o:T)
	{
		this.timer = 0;
		this.queueIndex = 0;
		this.animationType = Linear;
		this.target = o;
		this.queue = new Array();
		this.dir = 1;
		this.destroyed = false;
	}

	public function destroy()
	{
		this.destroyed = true;
	}

	private function updateQueueIndex()
	{
		queueIndex += dir;
		if (animationType == Linear)
		{
			queueIndex = queueIndex.clamp(0, queue.length);
		}
		else if (animationType == Loop)
		{
			queueIndex %= queue.length;
		}
		else if (animationType == PingPong)
		{
			if (queueIndex == -1)
			{
				dir = 1;
				queueIndex = 0;
			}
			else if (queueIndex == queue.length)
			{
				dir = -1;
				queueIndex = queue.length - 1;
			}
		}
	}

	public function add(action:IAnimatorAction)
	{
		queue.push(action);
	}

	public function callback(fn:Void->Void)
	{
		var action = new AnimatorCallbackAction(fn);
		queue.push(action);
	}

	public function alpha(time:Float, add:Float, easing:Float->Float)
	{
		var action = new AnimatorAlphaAction(target, time, add, easing);
		queue.push(action);
	}

	public function wait(time:Float)
	{
		var wait = new AnimatorWaitAction(time);
		queue.push(wait);
	}

	public function move(time:Float, x:Float, y:Float, ?easing:Float->Float)
	{
		easing = easing ?? Tween.linear;
		var moveAction = new AnimatorMoveAction(target, time, x, y, easing);
		queue.push(moveAction);
	}

	public function update(frame:engine.Frame):Void
	{
		if (isFinished())
		{
			this.destroyed = true;
			return;
		}

		if (current == null && queue.length > queueIndex)
		{
			do
			{
				current = queue[queueIndex];
				current.dir = dir;
				current.start();

				if (current.time != timer)
				{
					break;
				}
				else
				{
					updateQueueIndex();
				}
			}
			while (current != null && !isFinished());
		}
		else if (current != null)
		{
			if (timer == current.time)
			{
				current = null;
				timer = 0;
				updateQueueIndex();
			}
			else
			{
				timer = (timer += frame.dt).clamp(0, current.time);
			}
		}
	}

	public function postupdate()
	{
		if (destroyed)
			return;

		if (current != null)
		{
			current.update(timer / current.time);
		}
	}

	public function isFinished()
	{
		return animationType == Linear && queueIndex == queue.length;
	}

	public function isDisposed()
	{
		return destroyed;
	}
}
