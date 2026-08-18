package plib.types;

/**
	Read-only completion state for asynchronous work.

	The consumer may observe completion but cannot complete the task.
**/
interface ICompletionTask
{
	function isComplete():Bool;
	function onComplete(callback:Void->Void):Void;
}
