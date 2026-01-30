package plib.common.animator;

class Animator extends plib.engine.UpdateTreeNode
{
	var queue:plib.common.structs.Queue<PriorityNode>;
	var queueCur:Null<PriorityNode>;
	var unqueued:Array<PriorityNode>;
	var unqueuedCount:Int;

	var queuedPaused:Bool;
	var unqueuedPaused:Bool;
	var skip:Bool;

	public var isAnimating(get, never):Bool;

	public function new(limit = 64)
	{
		super();
		queue = new plib.common.structs.Queue(limit);
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

	public function create(id:String = '')
	{
		var node = new PriorityNode(id);
		unqueued.push(node);
		unqueuedCount++;
		return node;
	}

	public function createQueued(id:String = '')
	{
		var node = new PriorityNode(id);
		queue.enqueue(node);
		return node;
	}

	/**
		Cancel an unqueued animation.
	**/
	public function cancel(id:String)
	{
		for (anim in unqueued)
		{
			if (anim.id == id)
			{
				unqueued.remove(anim);
				break;
			}
		}
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

	override function update(frame:plib.engine.Frame)
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

	override function postupdate()
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
