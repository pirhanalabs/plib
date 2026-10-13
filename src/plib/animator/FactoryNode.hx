package plib.animator;

import plib.engine.Frame;

private abstract class TreeNode extends AnimatorNode
{
	var children:Array<AnimatorNode>;

	public function new(parent:FactoryNode)
	{
		if (parent != null)
		{
			this.parent = parent;
			parent.children.push(this);
		}
		children = [];
	}
}

/** 
	Base for queue and group animation. 
**/
@:noCompletion
abstract class FactoryNode extends TreeNode
{
	private function new(parent:FactoryNode)
	{
		super(parent);
	}

	/** 
		Creates a queued factory node. Children will
		trigger in order.
	**/
	public function queue():QueueNode
	{
		return new QueueNode(this);
	}

	/** 
		Creates a parallel factory node. Children will
		trigger all at the same time.
	**/
	public function group():GroupNode
	{
		return new GroupNode(this);
	}

	/** 
		Adds a callback animation node. 
	**/
	public function anim<T>(seconds:Float, target:T, callback:(target:T, ratio:Float) -> Void):AnimatorNode
	{
		return add(new AnimationNode(seconds, target, callback));
	}

	/** 
		Adds a delay. 
	**/
	public function wait(seconds:Float):AnimatorNode
	{
		return add(new WaitNode(seconds));
	}

	/** 
		Adds an immediate action that does not consume a frame. 
	**/
	public function fn(callback:Void->Void):AnimatorNode
	{
		return add(new FnNode(callback));
	}

	/**
		Adds an animator node to this factory.
	**/
	public function add<T:AnimatorNode>(node:T):T
	{
		if (isPrepared())
			throw 'Cannot add children to a running animator factory.';

		if (node.parent != null && node.parent != this)
			throw 'Animator node already belongs to another factory.';

		if (!children.contains(node))
		{
			children.push(node);
			node.parent = this;
		}
		return node;
	}

	// public function cancel(node:AnimatorNode):Bool
	// {
	// 	if (isPrepared())
	// 		throw 'Cannot remove children from a running animator factory.';
	// 	var childIndex = children.indexOf(node);
	// 	if (childIndex < 0)
	// 		return false;
	// 	children.splice(childIndex, 1);
	// 	node.parent = null;
	// 	onChildRemoved(node, childIndex);
	// 	return true;
	// }
	// private function onChildRemoved(node:AnimatorNode, childIndex:Int) {}
}
