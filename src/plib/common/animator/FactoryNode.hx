package plib.common.animator;

class FactoryNode extends AnimatorNode
{
	var cb:Void->Void;

	/**
		Sets the callback function that triggers when the factory node is completed.
	**/
	public function done(cb:Void->Void)
	{
		this.cb = cb;
		return this;
	}

	/**
		Simple animation node.
	**/
	public function anim<T>(stime:Float, o:T, fn:Float->T->Void)
	{
		var a = new AnimationNode<T>(stime, o, fn);
		addChild(a);
		return a;
	}

	/**
		Creates a new queue.
	**/
	public function queue()
	{
		var q = new QueueNode();
		addChild(q);
		return q;
	}

	/**
		Creates a new group.
	**/
	public function group()
	{
		var g = new GroupNode();
		addChild(g);
		return g;
	}

	/**
		Creates a callback function that triggers once this
		node is reached. This is mostly useful with queues or
		to delay execution.
	**/
	public function fn(fn:Void->Void)
	{
		var f = new CallbackNode(fn);
		addChild(f);
		return this;
	}

	/**
		Wait a certain amount of time.
	**/
	public function wait(stime:Float)
	{
		var w = new WaitNode(stime);
		addChild(w);
		return this;
	}

	/**
		Progresses when the callback returns true.
	**/
	public function waitComplete(fn:Void->Bool)
	{
		var c = new WaitCompleteNode(fn);
		addChild(c);
		return c;
	}

	/**
		Adds a custom node to the factory.
	**/
	public function add(node:AnimatorNode)
	{
		if (node == null)
			return null;

		addChild(node);
		return node;
	}

	override function callback()
	{
		if (cb != null)
		{
			cb();
		}
	}
}
