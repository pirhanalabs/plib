package plib.animator;

import plib.engine.Frame;

/** Base class for a single-use unit of animation work. **/
abstract class AnimatorNode
{
	private var parent:Null<FactoryNode> = null;
	private var prepared:Bool = false;

	/**
		Begins this node exactly once. Returns true when preparation happened
		during this call.
	**/
	public final function ensurePrepared():Bool
	{
		if (prepared)
			return false;

		prepared = true;
		prepare();
		return true;
	}

	public inline function isPrepared():Bool
	{
		return prepared;
	}

	@:allow(plib.animator.Animator)
	@:allow(plib.animator.GroupNode)
	@:allow(plib.animator.QueueNode)
	private function prepare() {}

	@:allow(plib.animator.Animator)
	@:allow(plib.animator.GroupNode)
	@:allow(plib.animator.QueueNode)
	private function update(frame:Frame) {}

	@:allow(plib.animator.Animator)
	@:allow(plib.animator.GroupNode)
	@:allow(plib.animator.QueueNode)
	private function postupdate() {}

	/** Must be a side-effect-free state query. **/
	public abstract function completed():Bool;
}
