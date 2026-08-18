package plib.engine.nodes.camera.effects;

import plib.Ease.EasingFunction;
import plib.Ease;
import plib.engine.nodes.camera.CameraEffects.CameraEffectOutput;

/** Instant screen-space displacement that eases back to rest. **/
class CameraBumpEffect extends TimedCameraEffect
{
	public final x:Float;
	public final y:Float;

	public function new(x:Float, y:Float, duration:Float = 0.15, ?ease:EasingFunction)
	{
		super(duration, ease == null ? Ease.outCubic : ease);
		this.x = x;
		this.y = y;
	}

	private function apply(ratio:Float, output:CameraEffectOutput)
	{
		var amount = 1 - ease(ratio);
		output.offsetX += x * amount;
		output.offsetY += y * amount;
	}
}
