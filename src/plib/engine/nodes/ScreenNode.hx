package plib.engine.nodes;

import plib.animator.Animator;
import plib.engine.nodes.LayerNode.ViewportMetrics;

/** Visual screen node with lifecycle state and an owned local animator. **/
class ScreenNode extends VisualNode
{
	/** Animator owned and processed by this screen. **/
	public final animator:Animator;

	public var manager(default, null):Null<ScreenManager>;

	public var entered(default, null):Bool;
	public var covered(default, null):Bool;
	public var exiting(default, null):Bool;

	/** Full-screen input surface, created immediately before `onEnter`. **/
	public var inputBlocker(default, null):Null<h2d.Interactive>;

	/** Default container for the screen's visual content. **/
	public var content(default, null):Null<h2d.Layers>;

	public function new(?display:h2d.Object)
	{
		super(display);

		animator = new Animator();

		manager = null;
		entered = false;
		covered = false;
		exiting = false;
	}

	// ---- Internal Screen Lifecycle ----

	@:allow(plib.engine.nodes.ScreenManager)
	private function attachToManager(manager:ScreenManager)
	{
		if (this.manager != null)
			throw 'Screen already belongs to a ScreenManager.';
		this.manager = manager;
	}

	@:allow(plib.engine.nodes.ScreenManager)
	private function enterScreen()
	{
		if (entered)
			return;

		entered = true;
		covered = false;
		exiting = false;

		var metrics = requireViewportMetrics();
		inputBlocker = new h2d.Interactive(metrics.wid, metrics.hei, display);
		inputBlocker.visible = true;
		inputBlocker.cursor = Default;
		content = new h2d.Layers(display);
		onResize();

		resume();
		onEnter();
	}

	override public function onResize()
	{
		super.onResize();
		if (viewportMetrics == null)
			return;
		if (inputBlocker != null)
		{
			inputBlocker.width = viewportMetrics.wid;
			inputBlocker.height = viewportMetrics.hei;
		}
		onViewportChanged(viewportMetrics);
	}

	@:allow(plib.engine.nodes.ScreenManager)
	private function coverScreen()
	{
		if (!entered || covered || exiting)
			return;

		covered = true;
		pause();
		if (inputBlocker != null)
			inputBlocker.visible = false;

		onCovered();
	}

	@:allow(plib.engine.nodes.ScreenManager)
	private function revealScreen()
	{
		if (!entered || !covered || exiting)
			return;

		covered = false;
		resume();
		if (inputBlocker != null)
			inputBlocker.visible = true;
		onRevealed();
	}

	@:allow(plib.engine.nodes.ScreenManager)
	private function exitScreen()
	{
		if (!entered || exiting)
			return;

		exiting = true;
		pause();
		if (inputBlocker != null)
			inputBlocker.visible = false;
		onExit();
	}

	// ---- Frame Lifecycle ----

	override function update(frame:Frame)
	{
		super.update(frame);
		animator.update(frame);
	}

	override function postupdate()
	{
		super.postupdate();
		animator.postupdate();
	}

	override function onDestroyed()
	{
		super.onDestroyed();
		animator.dispose();
		manager = null;
		inputBlocker = null;
		content = null;
		entered = false;
		covered = false;
		exiting = false;
	}

	// ---- User Lifecycle Callbacks ----

	/** Called once after the screen has been attached and becomes the top screen. **/
	public function onEnter() {}

	/** Called when another screen is pushed above this one. **/
	public function onCovered() {}

	/** Called when this screen becomes the top screen again. **/
	public function onRevealed() {}

	/** Called before this screen is removed and destroyed. **/
	public function onExit() {}

	/** Called after viewport dimensions or presentation scale change. **/
	public function onViewportChanged(viewport:ViewportMetrics) {}

	public inline function requestPop()
	{
		if (manager != null)
			manager.pop();
	}

	public inline function requestReplace(screen:ScreenNode)
	{
		if (manager != null)
			manager.replace(screen);
	}
}
