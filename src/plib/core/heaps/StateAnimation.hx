package core.heaps;

private typedef State = {
	frameDuration:Float,
	frames:Array<h2d.Tile>
}

class StateAnimation extends Animation {
	var states:Map<String, State>;

	public function new() {
		super([], 0.15);
		states = new Map();
	}

	public function add(id:String, frameDuration:Float = 0.15, frames:Array<Int>) {
		states.set(id, {
			frameDuration: frameDuration,
			frames: frames
		});
	}

	public function set(id:String) {
		if (states.exists(id)) {
			var state = states.get(id);
			setFrames(state.frames);
			frameDuration = state.frameDuration;
		}
	}
}
