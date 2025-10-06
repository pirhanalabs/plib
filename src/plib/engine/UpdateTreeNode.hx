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

	/**
		Destroys this item and flags it for garbage collection.
	**/
	public function destroy()
	{
		this.destroyed = true;
	}

	/**
		Triggers if the screen is destroyed.
		Use this to safely dispose of things.
		Override this in subclasses.
	**/
	public function dispose() {}

	/**
		Executes once per frame.
		Use this to update data.
		Override this in subclasses.
	**/
	private function update(frame:Frame) {}

	/**
		Executes once per frame.
		Use this to update visuals.
		Override this in subclasses.
	**/
	private function postupdate() {}

	/**
		Returns true if this node can run.
		This will affect all children as well.
	**/
	@:noCompletion
	public function __canRun()
	{
		return !paused && !destroyed;
	}

	/**
		Tries to update this node and all its children.
		This should only ever be called on root nodes.
	**/
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

	/**
		Tries to update this node and all its children.
		This should only ever be called on root nodes.
	**/
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
