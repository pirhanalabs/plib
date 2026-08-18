package plib.engine.nodes.camera.effects;

import plib.Ease.EasingFunction;
import plib.Ease;
import plib.M;
import plib.engine.Frame;
import plib.engine.nodes.camera.CameraEffects.CameraEffectOutput;

/** Finite procedural shake with independent translation and rotation strength. **/
class CameraShakeEffect implements CameraEffect
{
	private static var nextSeed:Int = 1;

	public final strength:Float;
	public final rotationStrength:Float;
	public final duration:Float;
	public final frequency:Float;
	public final falloff:EasingFunction;

	private final phase:Float;
	private var elapsed:Float = 0;
	private var completed:Bool = false;

	public function new(strength:Float, duration:Float, frequency:Float = 24, rotationStrength:Float = 0, ?falloff:EasingFunction)
	{
		if (duration < 0)
			throw 'Camera shake duration cannot be negative.';
		if (frequency < 0)
			throw 'Camera shake frequency cannot be negative.';

		this.strength = strength;
		this.rotationStrength = rotationStrength;
		this.duration = duration;
		this.frequency = frequency;
		this.falloff = falloff == null ? Ease.outQuad : falloff;
		phase = nextSeed++ * 1.61803398875;
	}

	public function update(frame:Frame, output:CameraEffectOutput)
	{
		if (completed)
			return;

		elapsed = duration == 0 ? 0 : M.min(elapsed + M.max(0.0, frame.dt), duration);

		var ratio = duration == 0 ? 1.0 : elapsed / duration;
		var amplitude = 1 - falloff(ratio);
		var angle = elapsed * frequency * M.PI2;

		output.offsetX += M.sin(angle + phase) * strength * amplitude;
		output.offsetY += M.sin(angle * 1.173 + phase * 2.17) * strength * amplitude;
		output.rotation += M.sin(angle * 0.847 + phase * 0.73) * rotationStrength * amplitude;

		if (ratio >= 1)
			completed = true;
	}

	public inline function isCompleted():Bool
	{
		return completed;
	}

	public function cancel()
	{
		completed = true;
	}
}
