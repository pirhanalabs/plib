package plib.engine.nodes.camera.effects;

import plib.engine.Frame;
import plib.engine.nodes.camera.CameraEffects.CameraEffectOutput;

/** A composable, screen-space camera effect managed by `CameraEffects`. **/
interface CameraEffect
{
	/** Adds this frame's contribution to `output`. **/
	function update(frame:Frame, output:CameraEffectOutput):Void;

	function isCompleted():Bool;
	function cancel():Void;
}
