package core.heaps;

class Process {
	public static final ALL:Array<Process> = [];

	public var root:h2d.Layers;
	public var parent:Process;
	public var children:Array<Process>;
	public var destroyed:Bool;

	public var ftime:Float = 0.0;

	@:noCompletion
	var _fixedtime:Float = 0.0;

	var frame:Null<Frame>;

	var paused:Bool;

	public function new(?parent:Process) {
		children = [];
		destroyed = false;
		paused = false;

		if (parent == null) {
			ALL.push(this);
		}
		else {
			parent.addChild(this);
		}
	}

	function addChild(child:Process) {
		ALL.remove(child);

		if (child.parent != null) {
			child.parent.children.remove(child);
		}

		child.parent = this;
		children.push(child);
	}

	function createRoot(ctx:h2d.Object) {
		if (root != null) {
			throw 'root already created';
		}
		root = new h2d.Layers(ctx);
	}

	function createRootInLayer(ctx:h2d.Layers, layer:Int) {
		ctx.add(root = new h2d.Layers(), layer);
	}

	function destroy() {
		destroyed = true;
	}

	public function pause() {
		this.paused = true;
	}

	public function resume() {
		this.paused = false;
	}

	/** called when the process is garbage collected. **/
	function dispose() {}

	/** called once per frame. **/
	function update(frame:Frame) {}

	/** called once per Application.FIXED_FPS. These are synced. **/
	function fixedupdate() {}

	/** called once per frame, after update and fixed update. **/
	function postupdate() {}

	private static inline function _canRun(p:Process) {
		return !p.destroyed && !p.paused;
	}

	private static function _update(p:Process, frame:Frame) {
		if (_canRun(p))
			return;

		p.frame = frame;
		p.ftime += frame.tmod;
		p.update(frame);

		if (_canRun(p))
			return;

		for (c in p.children) {
			_update(c, frame);
		}
	}

	private static function _fixedupdate(p:Process) {
		p._fixedtime += p.frame.tmod;

		while (p._fixedtime >= Application.FPS / Application.FIXED_FPS) {
			p._fixedtime -= Application.FPS / Application.FIXED_FPS;
			if (_canRun(p))
				return;

			p.fixedupdate();
		}

		if (_canRun(p))
			return;

		for (c in p.children) {
			_fixedupdate(c);
		}
	}

	private static function _postupdate(p:Process) {
		if (_canRun(p))
			return;

		p.postupdate();

		if (_canRun(p))
			return;

		for (c in p.children) {
			_postupdate(p);
		}
	}

	private static function _gc(list:Array<Process>) {
		var i = 0;

		while (i < list.length) {
			var p = list[i];
			if (p.destroyed) {
				_dispose(p);
			}
			else {
				_gc(p.children);
			}
			i++;
		}
	}

	private static function _dispose(p:Process) {
		for (c in p.children)
			c.destroy();
		_gc(p.children);

		ALL.remove(p);
		p.dispose();
	}

	public static function updateAll(frame:Frame) {
		for (p in ALL)
			_update(p, frame);
		for (p in ALL)
			_fixedupdate(p);
		for (p in ALL)
			_postupdate(p);
		_gc(ALL);
	}
}
