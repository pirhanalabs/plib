package plib.common.animator;

class FactoryNode extends AnimatorNode
{
	var cb:Void->Void;

	public function done(cb:Void->Void)
	{
		this.cb = cb;
		return this;
	}

	public function anim<T>(stime:Float, o:T, fn:Float->T->Void)
	{
		var a = new AnimationNode<T>(stime, o, fn);
		addChild(a);
		return a;
	}

	public function queue()
	{
		var q = new QueueNode();
		addChild(q);
		return q;
	}

	public function group()
	{
		var g = new GroupNode();
		addChild(g);
		return g;
	}

	public function wait(stime:Float)
	{
		var w = new WaitNode(stime);
		addChild(w);
		return w;
	}

	public function waitComplete(fn:Void->Bool)
	{
		var c = new WaitCompleteNode(fn);
		addChild(c);
		return c;
	}

	public function add(node:AnimatorNode)
	{
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
