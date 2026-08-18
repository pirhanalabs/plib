package plib.engine.nodes.camera.effects;

import plib.Ease.EasingFunction;
import plib.engine.Frame;
import plib.engine.nodes.camera.CameraEffects.CameraEffectOutput;

/** Shared duration/easing lifecycle for finite camera effects. **/
abstract class TimedCameraEffect implements CameraEffect
{
	public final duration:Float;
	public final ease:EasingFunction;

	private var elapsed:Float = 0;
	private var completed:Bool = false;

	public function new(duration:Float, ease:EasingFunction)
	{
		if (duration < 0)
			throw 'Camera effect duration cannot be negative.';
		if (ease == null)
			throw 'Camera effect easing function cannot be null.';
		this.duration = duration;
		this.ease = ease;
	}

	public final function update(frame:Frame, output:CameraEffectOutput)
	{
		if (completed)
			return;
		elapsed = duration == 0 ? 0 : M.min(duration, elapsed + M.max(0.0, frame.dt));
		var ratio = duration == 0 ? 1.0 : elapsed / duration;
		apply(ratio, output);
		if (ratio >= 1)
			completed = true;
	}

	private abstract function apply(ratio:Float, output:CameraEffectOutput):Void;

	public inline function isCompleted():Bool
	{
		return completed;
	}

	public function cancel()
	{
		completed = true;
	}
}
