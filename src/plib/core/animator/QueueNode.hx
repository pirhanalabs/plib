package plib.core.animator;

class QueueNode extends FactoryNode
{
	var cur:Int;
	var count:Int;

	public function new()
	{
		super();
		cur = 0;
		count = 0;
	}

	override function addChild(c:AnimatorNode):AnimatorNode
	{
		count++;
		return super.addChild(c);
	}

	override function update(frame:plib.engine.Frame)
	{
		if (cur == count)
		{
			return;
		}

		if (cur != count)
		{
			if (children[cur].isComplete())
			{
				children[cur].callback();
				cur++;
				return;
			}
			children[cur].update(frame);
		}
	}

	override function postupdate()
	{
		if (cur != count)
		{
			children[cur].postupdate();
		}
	}

	override function isComplete()
	{
		return cur == count;
	}

	override function callback()
	{
		super.callback();
	}
}
