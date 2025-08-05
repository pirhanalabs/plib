package plib.core.animator;

/**
	Root node of all animation nodes.
**/
class AnimatorNode
{
	var parent:AnimatorNode;
	var children:Array<AnimatorNode>;

	public function new()
	{
		parent = null;
		children = [];
	}

	private function addChild(c:AnimatorNode)
	{
		c.parent = this;
		children.push(c);
		return c;
	}

	@:allow(core.animator.Animator)
	private function update(frame:plib.engine.Frame)
	{
		// override this
	}

	@:allow(core.animator.Animator)
	private function postupdate()
	{
		// override this
	}

	public function isComplete()
	{
		return true;
	}

	@:allow(plib.core.animator.Animator)
	private function callback()
	{
		// override this
	}
}
