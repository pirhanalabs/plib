package plib.engine;

interface IApplication
{
	/**
		Viewport width
	**/
	var vw(default, null):Int;

	/**
		Viewport height	
	**/
	var vh(default, null):Int;

	/**
		Viewport half width
	**/
	var vw2(default, null):Float;

	/**
		viewport half height
	**/
	var vh2(default, null):Float;

	/**
		Pushes a screen on the stack.
	**/
	function pushScreen(screen:Screen):Void;

	/**
		Pops the last screen from the stack.
	**/
	function popScreen():Screen;

	/**
		Gets the custom cursor handler.
	**/
	function getCursor():CustomCursor;

	/**
		Gets the window instance.
	**/
	function getWindow():hxd.Window;
}
