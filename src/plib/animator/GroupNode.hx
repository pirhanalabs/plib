package plib.animator;

import plib.engine.Frame;

/** Concurrent fluent timeline used by `group()`. **/
class GroupNode extends FactoryNode
{
	private var done:Bool = false;
	private final completedChildren:Map<AnimatorNode, Bool> = [];
	public function new(parent:Null<FactoryNode>) super(parent);
	override function update(frame:Frame)
	{
		for (child in children)
		{
			if (!completedChildren.exists(child)) { prepareChild(child); continue; }
			if (!completedChildren.get(child))
			{
				var completed = child.completed(); completedChildren.set(child, completed);
				if (!completed) child.update(frame);
			}
		}
		checkCompletion();
	}
	override function postupdate()
	{
		for (child in children)
			if (completedChildren.exists(child) && !completedChildren.get(child)) child.postupdate();
	}
	override function prepare()
	{
		for (child in children) if (!completedChildren.exists(child)) prepareChild(child);
		checkCompletion();
	}
	private function prepareChild(child:AnimatorNode)
	{
		child.ensurePrepared(); completedChildren.set(child, child.completed());
	}
	private function checkCompletion()
	{
		done = true;
		for (child in children) if (!completedChildren.exists(child) || !completedChildren.get(child))
		{
			done = false; return;
		}
	}
	override function onChildRemoved(child:AnimatorNode, childIndex:Int)
	{
		completedChildren.remove(child); checkCompletion();
	}
	public function completed():Bool return done || children.length == 0;
}
