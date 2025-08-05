package core.structs;

abstract Position({x:Int, y:Int}) {
	public var x(get, set):Int;
	public var y(get, set):Int;

	public static function distance(first:Position, other:Position) {
		final dx = first.x - other.x;
		final dy = first.x - other.y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	inline function get_x() {
		return this.x;
	}

	inline function get_y() {
		return this.y;
	}

	inline function set_x(val:Int) {
		return this.x = val;
	}

	inline function set_y(val:Int) {
		return this.y = val;
	}

	public function new(x:Int, y:Int, ?id:Int) {
		this = {x: x, y: y};
	}

	public function inverse() {
		return new Position(this.x * -1, this.y * -1);
	}

	@:op(a == b)
	function op_is(pos:Position) {
		return pos.x == this.x && pos.y == this.y;
	}

	@:op(a != b)
	function op_not(pos:Position) {
		return !(this.x == pos.x && this.y == pos.y);
	}

	@:op(a + b)
	function op_add(pos:Position):Position {
		return new Position(this.x + pos.x, this.y + pos.y);
	}
}
