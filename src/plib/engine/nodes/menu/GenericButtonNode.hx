package plib.engine.nodes.menu;

/** Basic labeled button with deferred state-dependent background drawing. **/
class GenericButtonNode extends MenuElementNode
{
	public final background:h2d.Graphics;
	public final label:h2d.Text;
	public var width(default, set):Float;
	public var height(default, set):Float;
	public var normalColor:Int = 0x30343B;
	public var focusedColor:Int = 0x52606D;
	public var pressedColor:Int = 0x1F8EFA;
	public var disabledColor:Int = 0x181A1F;
	public var textColor:Int = 0xFFFFFF;

	private var dirty:Bool = true;

	/** Creates a ready-to-use text button with an explicit interactive rectangle. **/
	public function new(font:h2d.Font, text:String, width:Float, height:Float, ?callback:GenericButtonNode->Bool)
	{
		if (font == null)
			throw 'GenericButtonNode requires a font.';
		if (width < 0 || height < 0)
			throw 'Generic button dimensions cannot be negative.';
		super(null, callback == null ? null : element -> callback(cast element));
		background = new h2d.Graphics(display);
		label = new h2d.Text(font, display);
		label.text = text == null ? "" : text;
		this.width = width;
		this.height = height;
		interactive.width = width;
		interactive.height = height;
	}

	/** Changes the label and returns this button for chaining. **/
	public function setText(value:String):GenericButtonNode
	{
		label.text = value == null ? "" : value;
		dirty = true;
		return this;
	}

	private function set_width(value:Float):Float
	{
		if (value < 0)
			throw 'Generic button width cannot be negative.';
		width = value;
		interactive.width = value;
		dirty = true;
		return value;
	}

	private function set_height(value:Float):Float
	{
		if (value < 0)
			throw 'Generic button height cannot be negative.';
		height = value;
		interactive.height = value;
		dirty = true;
		return value;
	}

	override function onFocused()
		dirty = true;

	override function onUnfocused()
		dirty = true;

	override function onPressed()
		dirty = true;

	override function onReleased()
		dirty = true;

	override function onAvailabilityChanged()
		dirty = true;

	override function postupdate()
	{
		super.postupdate();
		if (!dirty)
			return;
		dirty = false;
		var color = !enabled ? disabledColor : pressed ? pressedColor : focused ? focusedColor : normalColor;
		background.clear();
		background.beginFill(color);
		background.drawRect(0, 0, width, height);
		background.endFill();
		label.textColor = textColor;
		label.x = (width - label.textWidth) * 0.5;
		label.y = (height - label.textHeight) * 0.5;
	}
}
