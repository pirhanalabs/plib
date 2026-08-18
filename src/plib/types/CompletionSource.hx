package plib.types;

import plib.utils.Assert;

/** Producer half of a one-shot completion task; expose `task` and retain the source. **/
class CompletionSource
{
	/** Read-only consumer view used to observe completion. **/
	public final task:ICompletionTask;

	private final state:CompletionTask;

	/** Creates a pending completion source and task pair. **/
	public function new()
	{
		state = new CompletionTask();
		task = state;
	}

	/**
		Completes the task once.

		Returns true when this call completed it and false if it was
		already complete.
	**/
	public function complete()
	{
		return state.complete();
	}

	/** Creates an already-completed task; newly attached callbacks run immediately. **/
	public static function completed():ICompletionTask
	{
		var source = new CompletionSource();
		source.complete();
		return source.task;
	}
}

private class CompletionTask implements ICompletionTask
{
	private final callbacks:Array<Void->Void>;
	private var completeState:Bool;

	public function new()
	{
		callbacks = [];
		completeState = false;
	}

	public inline function isComplete()
	{
		return completeState;
	}

	public function onComplete(callback:Void->Void)
	{
		Assert.notNull(callback, 'Completion callback cannot be null');

		if (completeState)
		{
			callback();
		}
		else
		{
			callbacks.push(callback);
		}
	}

	public function complete()
	{
		if (completeState)
		{
			return false;
		}

		completeState = true;

		var pending = callbacks.copy();
		callbacks.resize(0);

		for (callback in pending)
		{
			callback();
		}
		return true;
	}
}
