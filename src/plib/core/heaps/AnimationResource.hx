package core.heaps;

import resources.TilesheetResource;

class AnimationResource
{
	public var frames:TilesheetResource;
	public var animations:Map<String, Array<h2d.Tile>>;

	public function new(frames:TilesheetResource)
	{
		this.frames = frames;
		animations = new Map<String, Array<h2d.Tile>>();
	}

	public function addAnimation(name:String, frames:Array<Int>)
	{
		var animation:Array<h2d.Tile> = [
			for (frame in frames)
				this.frames.tiles[frame]
		];
		animations.set(name, animation);
	}

	public function getAnimation(name:String):Array<h2d.Tile>
	{
		if (animations.exists(name))
		{
			return animations.get(name);
		}
		throw 'Animation not found: ' + name;
		return [];
	}
}
