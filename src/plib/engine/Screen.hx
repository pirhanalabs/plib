package plib.engine;

using plib.core.extensions.ArrayExtension;

@:allow(plib.engine.IApplication)
class Screen
{
	
	var app:plib.engine.IApplication;
	var root:h2d.Layers;
	var camera:plib.engine.Camera;
	var animator:plib.core.animator.Animator;
	var updateables:Array<IUpdateable>;

	/**
		Called when added to the screen stack, before `ready()`.
		This is to initialize the camera, mainly.
	**/
	@:noCompletion
	private final function __init(app:IApplication)
	{
		this.app = app;
		this.root = new h2d.Layers();
		animator = new plib.core.animator.Animator(64);
		camera = new plib.engine.Camera(root);
		camera.setViewport(app.vw, app.vh);

		updateables = new Array<IUpdateable>();
	}

	/**
		Called when the screen is added to the screen stack.
		Override this in subclasses to add behavior.
	**/
	private function ready()
	{
		animator.skipFrame();
	}

	/** 
		If the screen was unfocused and becomes focused, this will trigger. 
		Override this in subclasses to add behavior.
	**/
	private function focus() {}

	/** 
		Triggers whenever the screen becomes unfocused, like when it becomes overlayed by another screen. 
		Override this in subclasses to add behavior.
	**/
	private function unfocus() {}

	/**
		Triggers the frame the window has been resized.
		Override this in subclasses to add behavior.
	**/
	private function resize() {}

	/** 
		Triggers when the screen is removed from the screen stack.
		Override this in subclasses to add behavior.
	**/
	private function dispose() {}

	/** 
		Triggers once per frame. Use this to update game data.
		Override this in subclasses to add behavior.
	**/
	private function update(frame:plib.engine.Frame)
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
