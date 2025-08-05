package core.structs;

class Bounds
{
	public var x1:Int;
	public var y1:Int;
	public var x2:Int;
	public var y2:Int;

	public var wid(get, null):Int;
	public var hei(get, null):Int;

	public function new(x1:Int, y1:Int, x2:Int, y2:Int)
	{
		this.x1 = x1;
		this.y1 = y1;
		this.x2 = x2;
		this.y2 = y2;
	}

	inline function get_wid()
	{
		return this.x2 - this.x1;
	}

	inline function get_hei()
	{
		return this.y2 - this.y1;
	}

	public function contains(x:Int, y:Int)
	{
		return x >= this.x1 && y >= this.y1 && x <= this.x2 && y <= this.y2;
	}
}
