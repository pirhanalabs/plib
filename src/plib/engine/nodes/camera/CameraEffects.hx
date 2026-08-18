package plib.engine.nodes.camera;

import plib.Ease.EasingFunction;
import plib.M;
import plib.engine.Frame;
import plib.engine.nodes.camera.effects.CameraBumpEffect;
import plib.engine.nodes.camera.effects.CameraEffect;
import plib.engine.nodes.camera.effects.CameraRotationPunchEffect;
import plib.engine.nodes.camera.effects.CameraRumbleEffect;
import plib.engine.nodes.camera.effects.CameraShakeEffect;
import plib.engine.nodes.camera.effects.CameraZoomPunchEffect;

/** Additive render state produced by the active camera effects. **/
class CameraEffectOutput
{
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var rotation:Float = 0;
	public var zoom:Float = 0;

	public function new() {}

	@:allow(plib.engine.nodes.camera.CameraEffects)
	private function reset()
	{
		offsetX = offsetY = rotation = zoom = 0;
	}
}

/** Owns and combines temporary effects without changing a camera's logical state. **/
class CameraEffects
{
	public final output:CameraEffectOutput;
	public var enabled:Bool = true;
	public var translationScale:Float = 1;
	public var rotationScale:Float = 1;
	public var zoomScale:Float = 1;

	/** Defaults used by `addTrauma()`. Rotation is expressed in radians. **/
	public var traumaStrength:Float = 10;

	public var traumaRotation:Float = 0.015;
	public var traumaFrequency:Float = 22;
	public var traumaDecay:Float = 1.5;
	public var trauma(default, null):Float = 0;

	private final active:Array<CameraEffect> = [];
	private var traumaTime:Float = 0;

	public function new()
	{
		output = new CameraEffectOutput();
	}

	public function add<T:CameraEffect>(effect:T):T
	{
		if (effect == null)
			throw 'Cannot add a null camera effect.';
		active.push(effect);
		return effect;
	}

	public inline function bump(x:Float, y:Float, duration:Float = 0.15, ?ease:EasingFunction):CameraBumpEffect
	{
		return add(new CameraBumpEffect(x, y, duration, ease));
	}

	public inline function shake(strength:Float, duration:Float, frequency:Float = 24, rotationStrength:Float = 0, ?falloff:EasingFunction):CameraShakeEffect
	{
		return add(new CameraShakeEffect(strength, duration, frequency, rotationStrength, falloff));
	}

	public inline function zoomPunch(amount:Float, duration:Float = 0.2, ?ease:EasingFunction):CameraZoomPunchEffect
	{
		return add(new CameraZoomPunchEffect(amount, duration, ease));
	}

	public inline function rotationPunch(amount:Float, duration:Float = 0.2, ?ease:EasingFunction):CameraRotationPunchEffect
	{
		return add(new CameraRotationPunchEffect(amount, duration, ease));
	}

	public inline function rumble(strength:Float, frequency:Float = 18, rotationStrength:Float = 0):CameraRumbleEffect
	{
		return add(new CameraRumbleEffect(strength, frequency, rotationStrength));
	}

	/** Adds normalized trauma. Repeated impacts accumulate up to one. **/
	public function addTrauma(amount:Float):CameraEffects
	{
		trauma = Math.max(0, Math.min(1, trauma + amount));
		return this;
	}

	public inline function hasEffects():Bool
	{
		return trauma > 0 || active.length > 0;
	}

	public function stopAll()
	{
		for (effect in active)
			effect.cancel();

		active.resize(0);
		trauma = 0;
		output.reset();
	}

	/** Updates all effects and returns the stable, allocation-free output object. **/
	public function update(frame:Frame):CameraEffectOutput
	{
		output.reset();
		if (!enabled)
			return output;

		var write = 0;
		for (effect in active)
		{
			effect.update(frame, output);
			if (!effect.isCompleted())
				active[write++] = effect;
		}
		active.resize(write);

		if (trauma > 0)
		{
			var dt = M.max(0.0, frame.dt);
			traumaTime += dt;
			var amplitude = trauma * trauma;
			var angle = traumaTime * traumaFrequency * M.PI2;
			output.offsetX += M.sin(angle * 1.07 + 0.3) * traumaStrength * amplitude;
			output.offsetY += M.sin(angle * 1.31 + 2.1) * traumaStrength * amplitude;
			output.rotation += M.sin(angle * 0.91 + 4.2) * traumaRotation * amplitude;
			trauma = M.max(0.0, trauma - traumaDecay * dt);
		}

		output.offsetX *= translationScale;
		output.offsetY *= translationScale;
		output.rotation *= rotationScale;
		output.zoom *= zoomScale;

		return output;
	}
}
