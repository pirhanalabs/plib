package plib.core.animator;

class GroupNode extends FactoryNode
{
	var _isComplete:Bool;

	// this is my hacky way of telling which children
	// have finished, and to allow the trigger of callbacks.
	var completedChildren:Map<Int, AnimatorNode>;

	public function new()
	{
		super();
		_isComplete = false;
		completedChildren = [];
	}

	override function update(frame:plib.engine.Frame)
	{
		_isComplete = true;

		for (i in 0...children.length)
		{
			final child = children[i];
			if (completedChildren.exists(i))
			{
				continue;
			}
			if (child.isComplete())
			{
				completedChildren.set(i, child);
				child.callback();
				continue;
			}
			_isComplete = false;
			child.update(frame);
		}
	}

	override function postupdate()
	{
		for (child in children)
		{
			child.postupdate();
		}
	}

	override function isComplete()
	{
		return _isComplete;
	}

	override function callback()
	{
		completedChildren = [];

		if (cb != null)
		{
			this.cb();
		}
	}
}
