package plib.engine;

class ScreenComponent extends plib.engine.Screen
{
	/**
		The screen this screen component is attached to.
		This is also the UpdateTreeNode parent.
	**/
	private var screen:plib.engine.Screen;

	/**
		ScreenComponents are "Screens" within screens.
		They functionally behave the same way as regular screens,
		except they are added and removed from other screens' updateTree
		rather than the Application's.

		Unlike regular screens, the focus and unfocus methods are not
		automatically called. They serve no purpose, unless
		manually triggered.
	**/
	public function new(screen:plib.engine.Screen)
	{
		super();
		this.screen = screen;
		screen.addChild(this);

		// equivalent to __init
		this.app = screen.app;
		this.root = new h2d.Layers();
		animator = new plib.common.animator.Animator(64);
		camera = screen.camera;
		ready();
	}

	override function dispose()
	{
		super.dispose();
		this.root.remove();
	}
}
