package plib.animator;

import plib.engine.Frame;

/** Sequential fluent timeline used for roots and nested queues. **/
class QueueNode extends FactoryNode
{
	private var index:Int = 0;
	private var node:Null<AnimatorNode>;
	private var done:Bool = false;
	public function new(parent:Null<FactoryNode>) super(parent);
	override function update(frame:Frame)
	{
		checkCompletion();
		if (node != null) node.update(frame);
		findNext();
		done = node == null && index >= children.length;
	}
	override function postupdate()
	{
		findNext(); done = node == null && index >= children.length;
		if (node != null) node.postupdate();
		checkCompletion(); done = node == null && index >= children.length;
	}
	override function prepare() { findNext(); done = node == null && index >= children.length; }
	private function findNext()
	{
		while (node == null && index < children.length)
		{
			node = children[index++]; node.ensurePrepared(); checkCompletion();
		}
	}
	private function checkCompletion() if (node != null && node.completed()) node = null;
	override function onChildRemoved(removed:AnimatorNode, childIndex:Int)
	{
		if (removed == node) node = null;
		if (childIndex < index) index--;
		findNext(); done = node == null && index >= children.length;
	}
	public function completed():Bool return done || children.length == 0;
}
