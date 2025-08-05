package core.heaps;

class AnimationController
{
	public var animations:AnimationResource;
	public var currentAnimation:String;
	public var animation:Animation;

	public function new(animation:Animation, resources:AnimationResource)
	{
		this.animation = animation;
		this.animations = resources;
		this.currentAnimation = '';
	}

	public function setAnimation(name:String)
	{
		if (animations.animations.exists(name))
		{
			if (currentAnimation != name)
			{
				currentAnimation = name;
				var frames = animations.getAnimation(name);
				animation.setFrames(frames);
			}
		}
	}

	public function update(stime:Float)
	{
		if (animation != null)
		{
			animation.updateTime(stime);
		}
	}
}
