package plib.engine.nodes.camera.effects;

import plib.Ease.EasingFunction;
import plib.Ease;
import plib.engine.nodes.camera.CameraEffects.CameraEffectOutput;

/** Instant additive rotation that eases back to rest. **/
class CameraRotationPunchEffect extends TimedCameraEffect
{
	public final amount:Float;

	public function new(amount:Float, duration:Float = 0.2, ?ease:EasingFunction)
	{
		super(duration, ease == null ? Ease.outCubic : ease);
		this.amount = amount;
	}

	private function apply(ratio:Float, output:CameraEffectOutput)
	{
		output.rotation += amount * (1 - ease(ratio));
	}
}
