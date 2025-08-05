package plib.core.animator;

class AnimationTools
{
	/**
		gets a subrange ratio between two values.
	**/
	public static function subrng(val:Float, min:Float, max:Float)
	{
		return Math.min(1, Math.max(0, val - min) / (max - min));
	}
}
