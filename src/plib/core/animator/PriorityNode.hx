package plib.core.animator;

class PriorityNode extends FactoryNode
{
	public function new()
	{
		super();
	}

	override function addChild(c:AnimatorNode)
	{
		if (children.length > 1)
			throw "cannot have more than 1 child on a PriorityNode";
		children.push(c);
		return c;
	}

	override function update(frame:plib.engine.Frame)
	{
		if (children.length != 0)
		{
			children[0].update(frame);
		}
	}

	override function postupdate()
	{
		if (children.length != 0)
		{
			children[0].postupdate();
		}
	}

	override function isComplete()
	{
		if (children.length != 0)
		{
			return children[0].isComplete();
		}
		return true;
	}

	override function callback()
	{
		if (children.length != 0)
		{
			children[0].callback();
		}
		super.callback();
	}
}
