package plib.engine.nodes.camera.effects;

import plib.M;
import plib.engine.Frame;
import plib.engine.nodes.camera.CameraEffects.CameraEffectOutput;

/** Continuous procedural shake. Call `stop()` for an optional fade-out. **/
class CameraRumbleEffect implements CameraEffect
{
	private static var nextSeed:Int = 1;

	public var strength:Float;
	public var rotationStrength:Float;
	public var frequency:Float;

	private final phase:Float;
	private var elapsed:Float = 0;
	private var fadeDuration:Float = -1;
	private var fadeElapsed:Float = 0;
	private var completed:Bool = false;

	public function new(strength:Float, frequency:Float = 18, rotationStrength:Float = 0)
	{
		if (frequency < 0)
			throw 'Camera rumble frequency cannot be negative.';

		this.strength = strength;
		this.frequency = frequency;
		this.rotationStrength = rotationStrength;

		phase = nextSeed++ * 2.41421356237;
	}

	public function stop(fadeSeconds:Float = 0)
	{
		if (fadeSeconds < 0)
			throw 'Camera rumble fade duration cannot be negative.';

		if (fadeSeconds == 0)
		{
			completed = true;
		}
		else
		{
			fadeDuration = fadeSeconds;
			fadeElapsed = 0;
		}
	}

	public function update(frame:Frame, output:CameraEffectOutput)
	{
		if (completed)
			return;

		var dt = M.max(0.0, frame.dt);
		var amplitude = 1.0;
		elapsed += dt;

		if (fadeDuration >= 0)
		{
			fadeElapsed = M.min(fadeDuration, fadeElapsed + dt);
			amplitude = 1 - fadeElapsed / fadeDuration;

			if (fadeElapsed >= fadeDuration)
				completed = true;
		}

		var angle = elapsed * frequency * M.PI2;
		output.offsetX += M.sin(angle + phase) * strength * amplitude;
		output.offsetY += M.sin(angle * 1.193 + phase * 1.91) * strength * amplitude;
		output.rotation += M.sin(angle * 0.811 + phase) * rotationStrength * amplitude;
	}

	public inline function isCompleted():Bool
	{
		return completed;
	}

	public function cancel():Void
	{
		completed = true;
	}
}
