package plib.engine.nodes;

class VisualNode extends Node
{
	public final display:h2d.Object;

	public function new(?display:h2d.Object, unique:Bool = false)
	{
		super(unique);

		this.display = display != null ? display : new h2d.Object();
	}

	override function onShow()
	{
		display.visible = true;
	}

	override function onHide()
	{
		display.visible = false;
	}

	override function onAddedToTree()
	{
		super.onAddedToTree();

		var visualParent = findVisualParent();

		if (visualParent != null)
		{
			visualParent.display.addChild(display);
		}
		else
		{
			tree.visualRoot.addChild(display);
		}
	}

	override function onRemovedFromTree()
	{
		display.remove();
		super.onRemovedFromTree();
	}

	/**
		Find the nearest visual node above this node.
		Non-visual process nodes are skipped.
	**/
	private function findVisualParent():Null<VisualNode>
	{
		var current = parent;

		while (current != null)
		{
			if (Std.isOfType(current, VisualNode))
			{
				return cast current;
			}
			current = current.parent;
		}
		return null;
	}

	public function refreshVisualParent()
	{
		var visualParent = findVisualParent();

		if (visualParent != null)
			visualParent.display.addChild(display);
		else if (tree != null)
			tree.visualRoot.addChild(display);
	}

	override function reparent(stepfather:Node)
	{
		var oldTree = tree;
		super.reparent(stepfather);

		if (oldTree != null)
		{
			refreshVisualParent();
		}
	}
}
