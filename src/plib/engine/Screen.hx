package plib.engine;

using plib.common.extensions.ArrayExtension;

@:allow(plib.engine.Application)
class Screen extends UpdateTreeNode
{
	var app:plib.engine.Application;
	var root:h2d.Layers;
	var camera:plib.engine.Camera;
	var animator:plib.common.animator.Animator;

	var allowInputs:Bool;

	private function new()
	{
		super();
		allowInputs = true;
	}

	/**
		Called when added to the screen stack, before `ready()`.
		This is to initialize the camera, mainly.
	**/
	@:noCompletion
	private final function __init(app:Application)
	{
		this.app = app;
		this.root = new h2d.Layers();
		animator = new plib.common.animator.Animator(64);
		camera = new plib.engine.Camera(root);
		camera.setViewport(app.vw, app.vh);
		addChild(animator);
		addChild(camera);
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
	private function focus()
	{
		this.paused = false;
	}

	/** 
		Triggers whenever the screen becomes unfocused, like when it becomes overlayed by another screen. 
		Override this in subclasses to add behavior.
	**/
	private function unfocus()
	{
		this.paused = true;
	}

	/**
		Triggers the frame the window has been resized.
		Override this in subclasses to add behavior.
	**/
	private function resize() {}

	/** 
		Triggers when the screen is removed from the screen stack.
		Override this in subclasses to add behavior.
	**/
	override function dispose() {}

	/**
		This is always triggered before update, and only if
		`allowInputs` is true.
		Override this in subclasses if needed.
	**/
	private function handleInputs() {}

	/** 
		Triggers once per frame. Use this to update game data.
		Override this in subclasses to add behavior.
	**/
	override function update(frame:plib.engine.Frame) {}

	/** 
		Triggers once per frame. Use this to update game visuals.
		Override this in subclasses to add behavior.
	**/
	override function postupdate() {}

	// **********************************************************
	// 									 Common helper methods
	// **********************************************************

	/**
		Centers an object horizontally on the screen.
	**/
	private inline function centerX(obj:h2d.Object)
	{
		obj.x = app.vw2 - obj.getSize().width * 0.5;
	}

	/**
		Centers an object vertically on the screen.
	**/
	private inline function centerY(obj:h2d.Object)
	{
		obj.y = app.vh2 - obj.getSize().height * 0.5;
	}

	/**
		Centers an object vertically and horizontally on the screen.
	**/
	private inline function centerXY(obj:h2d.Object)
	{
		centerX(obj);
		centerY(obj);
	}
}
