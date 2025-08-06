package plib.engine;

class plib.Screen
{
	@:allow(engine.IApplication)
	var app:engine.IApplication;

	@:allow(engine.IApplication)
	var root:h2d.Layers;

	@:allow(engine.IApplication)
	var camera:engine.Camera;

	var animator:core.animator.Animator;
	var updateables:Array<IUpdateable>;

	/**
		Called when added to the screen stack, before `ready()`.
		This is to initialize the camera, mainly.
	**/
	@:noCompletion
	@:allow(engine.IApplication)
	private final function __init(app:IApplication)
	{
		this.app = app;
		this.root = new h2d.Layers();
		animator = new core.animator.Animator(64);
		camera = new engine.Camera(root);
		camera.setViewport(app.vw, app.vh);

		updateables = new Array<IUpdateable>();
	}

	/**
		Called when the screen is added to the screen stack.
		Override this in subclasses to add behavior.
	**/
	@:allow(engine.IApplication)
	private function ready()
	{
		animator.skipFrame();
	}

	/** 
		If the screen was unfocused and becomes focused, this will trigger. 
		Override this in subclasses to add behavior.
	**/
	@:allow(engine.IApplication)
	private function focus() {}

	/** 
		Triggers whenever the screen becomes unfocused, like when it becomes overlayed by another screen. 
		Override this in subclasses to add behavior.
	**/
	@:allow(engine.IApplication)
	private function unfocus() {}

	/**
		Triggers the frame the window has been resized.
		Override this in subclasses to add behavior.
	**/
	@:allow(engine.IApplication)
	private function resize() {}

	/** 
		Triggers when the screen is removed from the screen stack.
		Override this in subclasses to add behavior.
	**/
	@:allow(engine.IApplication)
	private function dispose() {}

	/** 
		Triggers once per frame. Use this to update game data.
		Override this in subclasses to add behavior.
	**/
	@:allow(engine.IApplication)
	private function update(frame:engine.Frame)
	{
		animator.update(frame);
		camera.update(frame);

		updateables.fastUnsortedFilter(u -> !u.isDisposed());

		for (u in updateables)
		{
			if (!u.isDisposed())
			{
				u.update(frame);
			}
		}
	}

	/** 
		Triggers once per frame. Use this to update game visuals.
		Override this in subclasses to add behavior.
	**/
	@:allow(engine.IApplication)
	private function postupdate()
	{
		animator.postupdate();
		camera.postupdate();

		for (u in updateables)
		{
			if (!u.isDisposed())
			{
				u.postupdate();
			}
		}
	}
}
