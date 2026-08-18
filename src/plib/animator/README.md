# plib.animator

`plib.animator` is a small, frame-driven animation scheduler. It contains no
rendering dependency: an animation callback can modify a Heaps object, game
state, audio value, or any other target.

The normal API is `Animator` plus the fluent timeline returned by
`createAsync()` or `createQueued()`. `queue()`, `group()`, `anim()`, `wait()`,
and `fn()` cover ordinary composition. `QueueNode` and `GroupNode` remain
first-class types because timelines commonly retain or explicitly compose them.
Immediate animation, wait, and function implementations are private inside
`FactoryNode`; only extend `AnimatorNode` for reusable custom primitives.

## Driving the animator

Call `update(frame)` and then `postupdate()` exactly once per game frame:

```haxe
animator.update(frame);
animator.postupdate();
```

`update` advances elapsed time and resolves immediate work. `postupdate`
applies animation callbacks. The split allows game state to update before
animated values are written.

Calling either phase out of order throws. A callback exception propagates to
the caller after the animator restores its internal frame state.

## Creating timelines

`createAsync()` starts an independent root timeline. All async roots advance
together. `createQueued()` adds a root timeline to the serial line; only its
front root advances.

```haxe
var movement = animator.createAsync(() -> trace("movement complete"));
movement
	.anim(0.25, player, (player, ratio) -> player.x = 100 * ratio)
	.wait(0.1)
	.fn(() -> trace("done"));

var transition = animator.createQueued();
var parallel = transition.group();
parallel.anim(0.2, panel, (panel, ratio) -> panel.alpha = ratio);
parallel.anim(0.2, icon, (icon, ratio) -> icon.scaleX = ratio);
```

Factory methods are:

- `queue()` — children execute in order.
- `group()` — children execute concurrently.
- `anim(seconds, target, callback)` — emits ratios from `0` through `1`.
- `wait(seconds)` — delays subsequent queued work.
- `fn(callback)` — executes an immediate action.

Factories are mutable while being built and sealed when first prepared.
Attempting to add or remove children from a running factory throws. Animator
nodes are single-use and must not be attached to multiple factories.

## Timing contract

- `fn()` executes from `prepare()` and does not consume a frame.
- A zero-duration `anim()` invokes its callback once with ratio `1` during
  preparation and does not consume a frame.
- A positive animation emits ratio `0` in the `postupdate` of its activation
  frame. It begins accumulating elapsed time on the following update.
- Nested factories activate in the same frame as their parent; nesting does
  not add an extra delay.
- `completed()` is a pure state query. It must never invoke callbacks.
- Roots added from callbacks become active at the next frame boundary.
- Natural completion invokes the root completion callback exactly once.
- Cancellation and clearing never invoke completion callbacks.

## Pausing, clearing, and cancellation

Async and queued lines can be controlled independently or together:

```haxe
animator.pauseAsync();
animator.pauseQueued();
animator.pauseAll();

animator.resumeAsync();
animator.resumeQueued();
animator.resumeAll();

animator.clearAsync();
animator.clearQueued();
animator.clearAll();
animator.cancel(root);
```

A paused line receives neither phase and therefore accumulates no time.
Cancellation during a callback prevents the cancelled root from receiving
later work in that frame.

## Queued capacity

The serial root queue has a fixed capacity, defaulting to 64. This limit counts
only roots created with `createQueued()`; nested animations and factories do
not consume additional root slots.

The fixed capacity is intentional: it avoids queue growth during gameplay and
turns runaway scheduling into an immediate error. Applications that genuinely
need more queued roots can configure it:

```haxe
var animator = new Animator(256);
```

Sixty-four is a practical default when timelines contain their related work as
children. Increase it deliberately rather than silently dropping animations.

## Custom nodes

Extend `AnimatorNode` and implement the pure `completed()` query. Node lifecycle
methods are internal to the package: preparation must occur once, updates may
occur once per active frame, and visible effects belong in `postupdate` unless
the node is explicitly an immediate action.

Prefer building new behavior from `queue`, `group`, `anim`, `wait`, and `fn`.
Custom nodes should only be necessary for reusable domain-specific animation
primitives.

## Tests and benchmarks

From the project root:

```sh
haxe tests.hxml
haxe benchmark.hxml
```

Both commands are headless. The tests cover timing, nesting, mutation,
pause/resume, cancellation, capacity, node hierarchy mutations, services, and
deferred work. Benchmarks report traversal time and retained heap change; they
do not enforce hardware-dependent pass/fail thresholds.
