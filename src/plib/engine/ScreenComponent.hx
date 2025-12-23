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
	public function new()
	{
		super();
	}

	private function _initComponent(screen:plib.engine.Screen, layer:Int = 1)
	{
		if (screen == null)
			throw 'screen parent cannot be null for ScreenComponent';

		this.screen = screen;
		screen.addChild(this);

		// equivalent to __init
		this.app = screen.app;
		this.root = new h2d.Layers();
		animator = new plib.common.animator.Animator(64);
		camera = screen.camera;

		screen.root.add(this.root, layer);
		addChild(animator);
	}

	override function dispose()
	{
		super.dispose();
		this.root.remove();

		if (this.parent != null)
		{
			this.parent.removeChild(this);
		}
	}
}
