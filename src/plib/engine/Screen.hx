package plib.engine;

using plib.core.extensions.ArrayExtension;

@:allow(plib.engine.Application)
class Screen
{
	
	var app:plib.engine.Application;
	var root:h2d.Layers;
	var camera:plib.engine.Camera;
	var animator:plib.core.animator.Animator;

	/**
		Called when added to the screen stack, before `ready()`.
		This is to initialize the camera, mainly.
	**/
	@:noCompletion
	private final function __init(app:Application)
	{
		this.app = app;
		this.root = new h2d.Layers();
		animator = new plib.core.animator.Animator(64);
		camera = new plib.engine.Camera(root);
		camera.setViewport(app.vw, app.vh);
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
	}

	/** 
		Triggers once per frame. Use this to update game visuals.
		Override this in subclasses to add behavior.
	**/
	private function postupdate()
	{
		animator.postupdate();
		camera.postupdate();
	}
}
