package plib.animator;

import plib.collections.Queue;
import plib.engine.Frame;

/** 
	Schedules animations.
**/
class Animator
{
	private final async:Array<AnimatorNode>;
	private final queued:Queue<AnimatorNode>;
	private final asyncFrame:Array<AnimatorNode>;
	private final pendingAsync:Array<AnimatorNode>;
	private final pendingQueued:Array<AnimatorNode>;
	private final cancelled:Map<AnimatorNode, Bool>;
	private final completionCallbacks:Map<AnimatorNode, () -> Void>;

	public var asyncPaused(default, null):Bool;
	public var queuedPaused(default, null):Bool;

	private var asyncRanThisFrame:Bool;
	private var queuedRanThisFrame:Bool;
	private var queuedNodeThisFrame:Null<AnimatorNode>;
	private var processingFrame:Bool;
	private var disposed:Bool;
	private final queuedCapacity:Int;

	/** 
		Creates an animator.

		Queued capacity affects queued only. Async animations are not bound.
	**/
	public function new(queuedCapacity:Int = 64)
	{
		if (queuedCapacity <= 0)
			throw 'Animator queued capacity must be greater than zero.';

		async = [];
		queued = new Queue(queuedCapacity);
		asyncFrame = [];
		pendingAsync = [];
		pendingQueued = [];
		cancelled = [];
		completionCallbacks = [];
		asyncPaused = false;
		queuedPaused = false;
		asyncRanThisFrame = false;
		queuedRanThisFrame = false;
		queuedNodeThisFrame = null;
		processingFrame = false;
		disposed = false;
		this.queuedCapacity = queuedCapacity;
	}

	/** 
		Pauses concurrent animations without changing their elapsed time. 
	**/
	public function pauseAsync()
	{
		asyncPaused = true;
	}

	/** 
		Pauses queued animations without changing their elapsed time. 
	**/
	public function pauseQueued()
	{
		queuedPaused = true;
	}

	/** 
		Pauses concurrent and queued animations, without changing their elapsed time. 
	**/
	public inline function pauseAll()
	{
		pauseAsync();
		pauseQueued();
	}

	/** 
		Resumes concurrent animations only.
	**/
	public function resumeAsync()
	{
		asyncPaused = false;
	}

	/** 
		Resumes queued animations only. 
	**/
	public function resumeQueued()
	{
		queuedPaused = false;
	}

	/** 
		Resumes both concurrent and queued animations.
	**/
	public inline function resumeAll()
	{
		resumeAsync();
		resumeQueued();
	}

	/** 
		Cancels all concurrent animations without firing callbacks. 
	**/
	public function clearAsync()
	{
		for (node in async)
			cancelRoot(node);

		for (node in pendingAsync)
			completionCallbacks.remove(node);
		pendingAsync.resize(0);

		if (!processingFrame)
		{
			compactAsync();
			cancelled.clear();
		}
	}

	/** 
		Cancels all queued animations without firing callbacks. 
	**/
	public function clearQueued()
	{
		while (queued.any())
		{
			var node = queued.dequeue();
			cancelled.set(node, true);
			completionCallbacks.remove(node);
		}

		for (node in pendingQueued)
			completionCallbacks.remove(node);
		pendingQueued.resize(0);

		if (!processingFrame)
			cancelled.clear();
	}

	/** 
		Cancels all animations without firing completion callbacks. 
	**/
	public inline function clearAll()
	{
		clearAsync();
		clearQueued();
	}

	/** 
		Returns true if this animator has been disposed. 
	**/
	public inline function isDisposed():Bool
	{
		return disposed;
	}

	/** 
		Returns whether any concurrent animations are scheduled. 
	**/
	public inline function hasAsync():Bool
	{
		return getAsyncCount() > 0;
	}

	/** 
		Returns whether any queued animations are scheduled. 
	**/
	public inline function hasQueued():Bool
	{
		return getQueuedCount() > 0;
	}

	/** 
		Returns whether any animations are scheduled. 
	**/
	public inline function hasAnimations():Bool
	{
		return hasAsync() || hasQueued();
	}

	/** 
		Returns the number of active and pending concurrent animations. 
	**/
	public inline function getAsyncCount():Int
	{
		var count = pendingAsync.length;
		for (node in async)
		{
			if (!cancelled.exists(node))
			{
				count++;
			}
		}
		return count;
	}

	/** 
		Returns the number of active and pending queued animations. 
	**/
	public inline function getQueuedCount():Int
	{
		return queued.getCount() + pendingQueued.length;
	}

	/**
		Creates an async QueueNode.
	**/
	public function createAsync(?onComplete:() -> Void):QueueNode
	{
		ensureAlive();
		var node = new QueueNode(null);
		if (processingFrame)
		{
			pendingAsync.push(node);
		}
		else
		{
			async.push(node);
		}
		if (onComplete != null)
		{
			completionCallbacks.set(node, onComplete);
		}
		return node;
	}

	/**
		Creates a queued QueueNode.
	**/
	public function createQueued(?onComplete:() -> Void):QueueNode
	{
		ensureAlive();
		if (getQueuedCount() >= queuedCapacity)
			throw 'Animator queued-node capacity exceeded.';

		var node = new QueueNode(null);
		if (processingFrame)
			pendingQueued.push(node);
		else
			queued.enqueue(node);
		if (onComplete != null)
			completionCallbacks.set(node, onComplete);
		return node;
	}

	/** 
		Cancels an animation timeline without invoking its completion callback. 
	**/
	public function cancel(node:QueueNode):Bool
	{
		var pendingIndex = pendingAsync.indexOf(node);
		if (pendingIndex >= 0)
		{
			pendingAsync.splice(pendingIndex, 1);
			completionCallbacks.remove(node);
			return true;
		}

		pendingIndex = pendingQueued.indexOf(node);
		if (pendingIndex >= 0)
		{
			pendingQueued.splice(pendingIndex, 1);
			completionCallbacks.remove(node);
			return true;
		}

		var asyncIndex = async.indexOf(node);
		if (asyncIndex >= 0)
		{
			cancelRoot(node);
			if (!processingFrame)
			{
				compactAsync();
				cancelled.remove(node);
			}
			return true;
		}

		if (queued.remove(node))
		{
			cancelled.set(node, true);
			completionCallbacks.remove(node);
			if (!processingFrame)
			{
				cancelled.remove(node);
			}
			return true;
		}

		return false;
	}

	/** 
		Update all animations. 
	**/
	public function update(frame:Frame)
	{
		if (disposed)
			return;
		if (processingFrame)
			throw 'Animator.update() called twice without postupdate().';

		processingFrame = true;
		try
		{
			asyncRanThisFrame = !asyncPaused;
			queuedRanThisFrame = !queuedPaused;
			queuedNodeThisFrame = null;

			if (asyncRanThisFrame)
			{
				asyncFrame.resize(0);
				for (node in async)
					if (!cancelled.exists(node))
						asyncFrame.push(node);

				for (node in asyncFrame)
				{
					if (cancelled.exists(node))
						continue;

					var began = node.ensurePrepared();
					if (node.completed())
					{
						completeRoot(node);
						continue;
					}

					// A newly activated tree receives its initial postupdate before
					// accumulating time. Actions may still finish during prepare().
					if (!began)
						node.update(frame);
				}
			}
			else
				asyncFrame.resize(0);

			if (queuedRanThisFrame)
			{
				var node = queued.peek();
				while (node != null && node.completed())
				{
					queued.dequeue();
					notifyCompleted(node);
					node = queued.peek();
				}

				if (node != null)
				{
					var began = node.ensurePrepared();
					if (node.completed())
					{
						queued.dequeue();
						completeRoot(node);
					}
					else
					{
						queuedNodeThisFrame = node;
						if (!began)
							node.update(frame);
					}
				}
			}
		}
		catch (error:Dynamic)
		{
			finishFrame();
			throw error;
		}
	}

	/** 
		Postupdate all animations.
	**/
	public function postupdate()
	{
		if (disposed)
		{
			return;
		}

		if (!processingFrame)
		{
			throw 'Animator.postupdate() called without update().';
		}

		try
		{
			if (asyncRanThisFrame)
			{
				for (node in asyncFrame)
				{
					if (cancelled.exists(node))
					{
						continue;
					}

					node.postupdate();
					if (node.completed())
					{
						completeRoot(node);
					}
				}
			}

			if (queuedRanThisFrame)
			{
				var node = queuedNodeThisFrame;
				if (node != null && !cancelled.exists(node) && queued.peek() == node)
				{
					node.postupdate();
					if (node.completed() && queued.peek() == node)
					{
						queued.dequeue();
						completeRoot(node);
					}
				}
			}

			finishFrame();
		}
		catch (error:Dynamic)
		{
			finishFrame();
			throw error;
		}
	}

	/** 
		Cancels all work and permanently prevents new timeline creation. 
	**/
	public function dispose()
	{
		if (disposed)
			return;

		clearAll();
		disposed = true;
	}

	private function notifyCompleted(node:AnimatorNode)
	{
		var callback = completionCallbacks.get(node);
		completionCallbacks.remove(node);
		// Callback exceptions intentionally propagate. The node is removed and
		// its callback registration is cleared first, leaving the animator in a
		// consistent state if the caller catches the exception.
		if (callback != null)
			callback();
	}

	private function completeRoot(node:AnimatorNode)
	{
		if (cancelled.exists(node))
			return;

		cancelled.set(node, true);
		notifyCompleted(node);
	}

	private function cancelRoot(node:AnimatorNode)
	{
		cancelled.set(node, true);
		completionCallbacks.remove(node);
	}

	private function compactAsync()
	{
		var write = 0;
		for (read in 0...async.length)
		{
			var node = async[read];
			if (!cancelled.exists(node))
			{
				async[write] = node;
				write++;
			}
		}
		async.resize(write);
	}

	private function finishFrame()
	{
		compactAsync();

		// async
		for (node in pendingAsync)
		{
			async.push(node);
		}
		pendingAsync.resize(0);

		// queued
		for (node in pendingQueued)
		{
			queued.enqueue(node);
		}
		pendingQueued.resize(0);

		cancelled.clear();
		asyncFrame.resize(0);
		queuedNodeThisFrame = null;
		processingFrame = false;
	}

	private function ensureAlive()
	{
		if (disposed)
			throw 'Cannot create animations on a disposed Animator.';
	}
}
