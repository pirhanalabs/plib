package plib.core.animator;

class Animator
{
	var queue:plib.core.structs.Queue<AnimatorNode>;
	var queueCur:Null<AnimatorNode>;
	var unqueued:Array<AnimatorNode>;
	var unqueuedCount:Int;

	var queuedPaused:Bool;
	var unqueuedPaused:Bool;
	var skip:Bool;

	public var isAnimating(get, never):Bool;

	public function new(limit = 64)
	{
		queue = new plib.core.structs.Queue(limit);
		unqueued = [];
		unqueuedCount = 0;

		queuedPaused = false;
		unqueuedPaused = false;
		skip = false;
	}

	inline function get_isAnimating()
	{
		return (queue.any() || unqueuedCount > 0) && !queuedPaused && !unqueuedPaused;
	}

	public function create()
	{
		var node = new PriorityNode();
		unqueued.push(node);
		unqueuedCount++;
		return node;
	}

	public function createQueued()
	{
		var node = new PriorityNode();
		queue.enqueue(node);
		return node;
	}

	public function pauseAll(paused:Bool)
	{
		pauseQueued(paused);
		pauseUnqueued(paused);
	}

	/** Skips the next animation node update call. Does not prevent node postupdate call. **/
	public function skipFrame()
	{
		skip = true;
	}

	public function pauseQueued(paused:Bool) {}

	public function pauseUnqueued(paused:Bool) {}

	public function update(frame:plib.engine.Frame)
	{
		// skip frame
		if (skip)
		{
			skip = false;
			return;
		}

		// unqueued are updated first
		var i = unqueued.length - 1;
		while (i >= 0)
		{
			final node = unqueued[i];
			if (node.isComplete())
			{
				node.callback();
				unqueued.remove(node);
				unqueuedCount--;
			}
			else
			{
				node.update(frame);
			}
			i--;
		}

		// update queued
		if (queue.any() || queueCur != null)
		{
			if (queueCur == null)
			{
				queueCur = queue.peek();
			}
			else if (queueCur.isComplete())
			{
				queue.dequeue().callback();
				queueCur = null;
			}
			else
			{
				queueCur.update(frame);
			}
		}
	}

	public function postupdate()
	{
		// postupdate unqueued
		for (node in unqueued)
		{
			node.postupdate();
		}

		// postupdate queued
		if (queueCur != null)
		{
			queueCur.postupdate();
		}
	}
}
