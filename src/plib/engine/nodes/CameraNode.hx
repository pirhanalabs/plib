package plib.engine.nodes;

import h2d.col.Point;
import plib.Ease.EasingFunction;
import plib.Ease;
import plib.Tween;
import plib.animator.Animator;
import plib.animator.QueueNode;
import plib.engine.Frame;
import plib.engine.nodes.LayerNode.ViewportMetrics;
import plib.engine.nodes.Node.NodeState;
import plib.engine.nodes.camera.CameraEffects.CameraEffectOutput;
import plib.engine.nodes.camera.CameraEffects;

/** Optional camera controller for one visual container. **/
class CameraNode extends Node
{
	public static inline final MIN_ZOOM:Float = 0.0001;

	/** Display container transformed by this camera. **/
	public final target:h2d.Object;

	public final viewport:ViewportMetrics;
	public final effects:CameraEffects;

	/** Authoritative camera center, zoom, and clockwise rotation. **/
	public var x(default, null):Float;

	public var y(default, null):Float;
	public var zoom(default, null):Float;
	public var rotation(default, null):Float;
	public var restoreTargetOnRemoval:Bool = true;

	private final animator:Animator;
	private var movement:Null<QueueNode>;
	private var zoomAnimation:Null<QueueNode>;
	private var rotationAnimation:Null<QueueNode>;
	private var followTarget:Null<h2d.Object>;
	private var followOffsetX:Float = 0;
	private var followOffsetY:Float = 0;
	private var followSmoothTime:Float = 0.15;
	private var followMaxSpeed:Float = 1e30;
	private final followVelocityX:{velocity:Float} = {velocity: 0};
	private final followVelocityY:{velocity:Float} = {velocity: 0};

	private var deadZoneEnabled:Bool = false;
	private var deadZoneX:Float = 0;
	private var deadZoneY:Float = 0;
	private var deadZoneWid:Float = 0;
	private var deadZoneHei:Float = 0;

	private var boundsEnabled:Bool = false;
	private var boundsX:Float = 0;
	private var boundsY:Float = 0;
	private var boundsWid:Float = 0;
	private var boundsHei:Float = 0;

	private var transformDirty:Bool = true;
	private var observedViewportRevision:Int;
	private var targetTransformApplied:Bool = false;
	private var effectOutput:CameraEffectOutput;
	private final originalX:Float;
	private final originalY:Float;
	private final originalScaleX:Float;
	private final originalScaleY:Float;
	private final originalRotation:Float;

	/** Creates a camera that transforms `target` using explicit viewport metrics. **/
	public function new(target:h2d.Object, viewport:ViewportMetrics, x:Float = 0, y:Float = 0, zoom:Float = 1, rotation:Float = 0)
	{
		super();
		if (target == null)
			throw 'CameraNode requires a display target.';
		if (viewport == null)
			throw 'CameraNode requires viewport metrics.';

		validateZoom(zoom);

		this.target = target;
		this.viewport = viewport;
		this.x = x;
		this.y = y;
		this.zoom = zoom;
		this.rotation = rotation;
		animator = new Animator();
		effects = new CameraEffects();
		effectOutput = effects.output;
		observedViewportRevision = viewport.revision;
		originalX = target.x;
		originalY = target.y;
		originalScaleX = target.scaleX;
		originalScaleY = target.scaleY;
		originalRotation = target.rotation;
	}

	// -------------------------------------------------------------------------
	// Immediate and animated state
	// -------------------------------------------------------------------------

	/** Moves immediately to a world-space camera center. **/
	public function setPosition(x:Float, y:Float):CameraNode
	{
		stopMovement();
		stopFollowing();
		setPositionInternal(x, y);
		return this;
	}

	/** Offsets the current world-space camera center. **/
	public function translate(dx:Float, dy:Float):CameraNode
	{
		return setPosition(x + dx, y + dy);
	}

	/** Applies a positive zoom immediately. **/
	public function setZoom(value:Float):CameraNode
	{
		validateZoom(value);
		stopZoom();
		setZoomInternal(value);
		return this;
	}

	/** Applies camera rotation in radians immediately. **/
	public function setRotation(value:Float):CameraNode
	{
		stopRotation();
		setRotationInternal(value);
		return this;
	}

	/** Centers immediately on an object's position in the target's coordinate space. **/
	public function centerOn(object:h2d.Object):CameraNode
	{
		var position = getTargetPosition(object);
		return setPosition(position.x, position.y);
	}

	/** Replaces the active movement tween and animates to a world-space center. **/
	public function moveTo(x:Float, y:Float, seconds:Float, ?ease:EasingFunction, ?onComplete:Void->Void):CameraNode
	{
		validateDuration(seconds);
		stopMovement();
		stopFollowing();

		var startX = this.x;
		var startY = this.y;
		var easing = ease == null ? Ease.outCubic : ease;
		var timeline:Null<QueueNode> = null;

		timeline = animator.createAsync(() ->
		{
			if (movement == timeline)
				movement = null;
			setPositionInternal(x, y);
			if (onComplete != null)
				onComplete();
		});

		movement = timeline;

		timeline.anim(seconds, this, (camera, ratio) ->
		{
			var t = easing(ratio);
			camera.setPositionInternal(Tween.lerp(startX, x, t), Tween.lerp(startY, y, t));
		});

		return this;
	}

	/** Replaces the active zoom tween and animates to a positive zoom. **/
	public function zoomTo(value:Float, seconds:Float, ?ease:EasingFunction, ?onComplete:Void->Void):CameraNode
	{
		validateZoom(value);
		validateDuration(seconds);
		stopZoom();

		var start = zoom;
		var easing = ease == null ? Ease.outCubic : ease;
		var timeline:Null<QueueNode> = null;

		timeline = animator.createAsync(() ->
		{
			if (zoomAnimation == timeline)
				zoomAnimation = null;
			setZoomInternal(value);
			if (onComplete != null)
				onComplete();
		});

		zoomAnimation = timeline;
		timeline.anim(seconds, this, (camera, ratio) -> camera.setZoomInternal(Tween.lerp(start, value, easing(ratio))));

		return this;
	}

	/** Replaces the active rotation tween and animates using the shortest angle. **/
	public function rotateTo(value:Float, seconds:Float, ?ease:EasingFunction, ?onComplete:Void->Void):CameraNode
	{
		validateDuration(seconds);
		stopRotation();

		var start = rotation;
		var easing = ease == null ? Ease.outCubic : ease;
		var timeline:Null<QueueNode> = null;

		timeline = animator.createAsync(() ->
		{
			if (rotationAnimation == timeline)
				rotationAnimation = null;
			setRotationInternal(value);
			if (onComplete != null)
				onComplete();
		});

		rotationAnimation = timeline;
		timeline.anim(seconds, this, (camera, ratio) -> camera.setRotationInternal(Tween.angle(start, value, easing(ratio))));

		return this;
	}

	private function setPositionInternal(x:Float, y:Float)
	{
		this.x = x;
		this.y = y;
		clampPosition();
		transformDirty = true;
	}

	private function setZoomInternal(value:Float)
	{
		zoom = M.max(MIN_ZOOM, value);
		clampPosition();
		transformDirty = true;
	}

	private function setRotationInternal(value:Float)
	{
		rotation = value;
		clampPosition();
		transformDirty = true;
	}

	// -------------------------------------------------------------------------
	// Following and screen-space dead zone
	// -------------------------------------------------------------------------

	/** Smoothly follows any display object, independent of logical node ownership. **/
	public function follow(object:h2d.Object, offsetX:Float = 0, offsetY:Float = 0, smoothTime:Float = 0.15, maxSpeed:Float = 1e30):CameraNode
	{
		if (object == null || object == target)
			throw 'Camera follow target is invalid.';
		if (smoothTime < 0)
			throw 'Camera follow smooth time cannot be negative.';
		if (maxSpeed <= 0)
			throw 'Camera follow maximum speed must be greater than zero.';
		stopMovement();
		followTarget = object;
		followOffsetX = offsetX;
		followOffsetY = offsetY;
		followSmoothTime = smoothTime;
		followMaxSpeed = maxSpeed;
		resetFollowVelocity();
		return this;
	}

	/** Dead-zone rectangle in viewport coordinates relative to its center. **/
	public function setFollowDeadZone(x:Float, y:Float, wid:Float, hei:Float):CameraNode
	{
		if (wid < 0 || hei < 0)
			throw 'Camera follow dead-zone dimensions cannot be negative.';
		deadZoneEnabled = true;
		deadZoneX = x;
		deadZoneY = y;
		deadZoneWid = wid;
		deadZoneHei = hei;
		return this;
	}

	/** Removes the follow dead zone so the target is always tracked. **/
	public function clearFollowDeadZone():CameraNode
	{
		deadZoneEnabled = false;
		return this;
	}

	/** Releases the follow target without changing current position. **/
	public function stopFollowing():CameraNode
	{
		followTarget = null;
		resetFollowVelocity();
		return this;
	}

	/** Reports whether a live display target is assigned. **/
	public inline function isFollowing():Bool
		return followTarget != null;

	private function updateFollowing(frame:Frame)
	{
		var object = followTarget;
		if (object == null)
			return;
		var scene = target.getScene();
		if (scene == null || object.getScene() != scene || !isInCameraSpace(object))
		{
			stopFollowing();
			return;
		}
		var position = getTargetPosition(object);
		var desiredX = position.x + followOffsetX;
		var desiredY = position.y + followOffsetY;

		if (deadZoneEnabled)
		{
			var dx = desiredX - x;
			var dy = desiredY - y;
			var c = M.cos(rotation);
			var s = M.sin(rotation);
			var screenX = zoom * (c * dx + s * dy);
			var screenY = zoom * (-s * dx + c * dy);
			var correctionX = axisCorrection(screenX, deadZoneX, deadZoneX + deadZoneWid);
			var correctionY = axisCorrection(screenY, deadZoneY, deadZoneY + deadZoneHei);
			desiredX = x + (c * correctionX - s * correctionY) / zoom;
			desiredY = y + (s * correctionX + c * correctionY) / zoom;
		}

		if (followSmoothTime == 0)
		{
			x = desiredX;
			y = desiredY;
			resetFollowVelocity();
		}
		else
		{
			x = Tween.smoothdamp(x, desiredX, followVelocityX, followSmoothTime, frame.dt, followMaxSpeed);
			y = Tween.smoothdamp(y, desiredY, followVelocityY, followSmoothTime, frame.dt, followMaxSpeed);
		}
		clampPosition();
		transformDirty = true;
	}

	private static inline function axisCorrection(value:Float, minimum:Float, maximum:Float):Float
	{
		return value < minimum ? value - minimum : value > maximum ? value - maximum : 0;
	}

	private function resetFollowVelocity()
	{
		followVelocityX.velocity = 0;
		followVelocityY.velocity = 0;
	}

	// -------------------------------------------------------------------------
	// World bounds
	// -------------------------------------------------------------------------

	/** Constrains the visible camera rectangle to world bounds when geometrically possible. **/
	public function setBounds(x:Float, y:Float, wid:Float, hei:Float):CameraNode
	{
		if (wid < 0 || hei < 0)
			throw 'Camera bounds dimensions cannot be negative.';
		boundsEnabled = true;
		boundsX = x;
		boundsY = y;
		boundsWid = wid;
		boundsHei = hei;
		clampPosition();
		transformDirty = true;
		return this;
	}

	/** Removes world-bound clamping. **/
	public function clearBounds():CameraNode
	{
		boundsEnabled = false;
		return this;
	}

	/** Reports whether world bounds are active. **/
	public inline function hasBounds():Bool
		return boundsEnabled;

	private function clampPosition()
	{
		if (!boundsEnabled)
			return;
		var halfW = viewport.wid / (zoom * 2);
		var halfH = viewport.hei / (zoom * 2);
		var c = M.abs(M.cos(rotation));
		var s = M.abs(M.sin(rotation));
		var visibleW = c * halfW + s * halfH;
		var visibleH = s * halfW + c * halfH;
		var minX = boundsX + visibleW;
		var maxX = boundsX + boundsWid - visibleW;
		var minY = boundsY + visibleH;
		var maxY = boundsY + boundsHei - visibleH;
		x = minX > maxX ? boundsX + boundsWid * 0.5 : M.max(minX, M.min(maxX, x));
		y = minY > maxY ? boundsY + boundsHei * 0.5 : M.max(minY, M.min(maxY, y));
	}

	// -------------------------------------------------------------------------
	// Cancellation and coordinates
	// -------------------------------------------------------------------------

	/** Cancels the active position tween and reports whether one existed. **/
	public function stopMovement():Bool
	{
		var value = movement;
		movement = null;
		return value != null && animator.cancel(value);
	}

	/** Cancels the active zoom tween and reports whether one existed. **/
	public function stopZoom():Bool
	{
		var value = zoomAnimation;
		zoomAnimation = null;
		return value != null && animator.cancel(value);
	}

	/** Cancels the active rotation tween and reports whether one existed. **/
	public function stopRotation():Bool
	{
		var value = rotationAnimation;
		rotationAnimation = null;
		return value != null && animator.cancel(value);
	}

	/** Cancels camera tweens, following, and transient effects. **/
	public function stopAll()
	{
		stopFollowing();
		movement = null;
		zoomAnimation = null;
		rotationAnimation = null;
		animator.clearAll();
		effects.stopAll();
		transformDirty = true;
	}

	/** Converts viewport-local screen coordinates into target world coordinates. **/
	public function screenToWorld(screenX:Float, screenY:Float):Point
	{
		ensureTargetInScene();
		return target.globalToLocal(new Point(screenX, screenY));
	}

	/** Converts target world coordinates into viewport-local screen coordinates. **/
	public function worldToScreen(worldX:Float, worldY:Float):Point
	{
		ensureTargetInScene();
		return target.localToGlobal(new Point(worldX, worldY));
	}

	/** Converts the current application mouse position into target world coordinates. **/
	public function mouseToWorld():Point
	{
		var scene = ensureTargetInScene();
		return screenToWorld(scene.mouseX, scene.mouseY);
	}

	/** Resolves an object's origin into the camera target's coordinate space. **/
	public function getTargetPosition(object:h2d.Object):Point
	{
		if (object == null)
			throw 'Camera position target cannot be null.';
		var scene = ensureTargetInScene();
		if (object.getScene() != scene)
			throw 'Camera objects must share one h2d.Scene.';
		if (!isInCameraSpace(object))
			throw 'Camera targets must be descendants of the camera display target.';
		return target.globalToLocal(object.localToGlobal(new Point()));
	}

	private function isInCameraSpace(object:h2d.Object):Bool
	{
		var current:Null<h2d.Object> = object;
		while (current != null)
		{
			if (current == target)
				return true;
			current = current.parent;
		}
		return false;
	}

	private function ensureTargetInScene():h2d.Scene
	{
		var scene = target.getScene();
		if (scene == null)
			throw 'Camera target is not attached to an h2d.Scene.';
		return scene;
	}

	// -------------------------------------------------------------------------
	// Lifecycle and final render transform
	// -------------------------------------------------------------------------

	override function update(frame:Frame)
	{
		super.update(frame);
		updateFollowing(frame);
		animator.update(frame);
		effectOutput = effects.update(frame);
		// Effects may finish on this update; always applying clears their final
		// render offset instead of leaving the target at its last shaken pose.
		transformDirty = true;
	}

	override function postupdate()
	{
		super.postupdate();
		animator.postupdate();
		if (observedViewportRevision != viewport.revision)
		{
			observedViewportRevision = viewport.revision;
			clampPosition();
			transformDirty = true;
		}
		if (transformDirty)
		{
			transformDirty = false;
			applyTransform();
		}
	}

	override function onRemovedFromTree()
	{
		stopAll();
		restoreTargetIfNeeded();
		super.onRemovedFromTree();
	}

	override function onDestroyed()
	{
		stopAll();
		animator.dispose();
		restoreTargetIfNeeded();
		super.onDestroyed();
	}

	private function applyTransform()
	{
		var renderZoom = M.max(MIN_ZOOM, zoom + effectOutput.zoom);
		var renderRotation = rotation + effectOutput.rotation;
		var c = M.cos(renderRotation);
		var s = M.sin(renderRotation);
		target.scaleX = renderZoom;
		target.scaleY = renderZoom;
		target.rotation = -renderRotation;
		target.x = viewport.centerX - (c * x + s * y) * renderZoom + effectOutput.offsetX;
		target.y = viewport.centerY + (s * x - c * y) * renderZoom + effectOutput.offsetY;
		targetTransformApplied = true;
	}

	private function restoreTargetIfNeeded()
	{
		if (!restoreTargetOnRemoval || !targetTransformApplied)
			return;
		target.x = originalX;
		target.y = originalY;
		target.scaleX = originalScaleX;
		target.scaleY = originalScaleY;
		target.rotation = originalRotation;
		targetTransformApplied = false;
	}

	private static function validateDuration(seconds:Float)
	{
		if (seconds < 0)
			throw 'Camera animation duration cannot be negative.';
	}

	private static function validateZoom(value:Float)
	{
		if (value <= 0)
			throw 'Camera zoom must be greater than zero.';
	}
}
