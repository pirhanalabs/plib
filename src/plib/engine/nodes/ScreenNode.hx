package plib.engine.nodes;

class ScreenNode extends VisualNode
{
	private var app(get, never):plib.engine.Application;
	private var animator:plib.common.animator.Animator;

	public function new()
	{
		super(new h2d.Object());

		animator = new plib.common.animator.Animator(64);
	}

	/** Called when this screen becomes the top scene. **/
	public function onEnter() {}

	/** Called when another screen is placed above this one. **/
	public function onCovered() {}

	/** Called when a scene above this one is removed. **/
	public function onRevealed() {}

	/** Called before this scene is removed from the stack. **/
	public function onExit() {}

	override function update(frame:Frame)
	{
		super.update(frame);
		@:privateAccess animator.update(frame);
	}

	override function postupdate()
	{
		super.postupdate();
		@:privateAccess animator.postupdate();
	}

	override function onRemovedFromTree()
	{
		super.onRemovedFromTree();
		animator.dispose();
		animator = null;
	}

	override function onDestroyRequested()
	{
		super.onDestroyRequested();
		display.visible = false;
	}

	private inline function get_app()
	{
		return plib.engine.Application.get();
	}
}
