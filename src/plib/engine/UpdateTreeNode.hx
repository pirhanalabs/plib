package plib.engine;

class UpdateTreeNode
{
	public var destroyed:Bool;
	public var paused:Bool;

	public var parent(default, null):Null<UpdateTreeNode>;
	public var children(default, null):Array<UpdateTreeNode>;

	public function new(?parent:UpdateTreeNode)
	{
		this.children = [];
		this.destroyed = false;
		this.paused = false;

		if (parent != null)
		{
			parent.addChild(this);
		}
	}

	public function addChild(child:UpdateTreeNode)
	{
		if (child.parent != null)
		{
			child.parent.children.remove(child);
		}
		child.parent = this;
		this.children.push(child);
	}

	public function removeChild(child:UpdateTreeNode)
	{
		if (children.remove(child))
		{
			child.parent = null;
		}
	}

	public function destroy()
	{
		this.destroyed = true;
	}

	public function dispose() {}

	private function update(frame:Frame) {}

	private function postupdate() {}

	@:noCompletion
	private function __canRun()
	{
		return !paused && !destroyed;
	}

	@:noCompletion
	public function __update(frame:Frame)
	{
		if (!__canRun())
			return;

		update(frame);

		if (__canRun())
		{
			for (child in children)
			{
				child.__update(frame);
			}
		}
	}

	@:noCompletion
	public function __postupdate()
	{
		if (!__canRun())
			return;

		postupdate();

		if (__canRun())
		{
			for (child in children)
			{
				child.__postupdate();
			}
		}
	}

	@:noCompletion
	public function __gc()
	{
		if (destroyed)
		{
			for (child in children)
			{
				child.destroy();
				child.__gc();
			}

			if (this.parent != null && !this.parent.destroyed)
			{
				this.parent.children.remove(this);
			}

			this.dispose();
			this.parent = null;
			this.children = [];
		}
	}
}
