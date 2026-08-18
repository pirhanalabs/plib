package plib.types;

/** Disposable handle returned by `Signal.listen()`. **/
class SignalSubscription
{
	private var disposeCallback:Null<Void->Void>;
	@:allow(plib.types.Signal)
	private function new(callback:Void->Void) disposeCallback = callback;
	/** Detaches the listener once; subsequent calls do nothing. **/
	public function dispose()
	{
		if (disposeCallback == null) return;
		var callback = disposeCallback;
		disposeCallback = null;
		callback();
	}
}

/** Small synchronous signal with disposable listeners. **/
class Signal<T>
{
	private final listeners:Array<T->Void> = [];

	/** Creates a signal with no listeners. **/
	public function new() {}

	/** Registers a synchronous listener and returns its disposal handle. **/
	public function listen(listener:T->Void):SignalSubscription
	{
		if (listener == null)
			throw 'Input signal listener cannot be null.';
		listeners.push(listener);
		return new SignalSubscription(() -> listeners.remove(listener));
	}

	/** Calls a snapshot of listeners in registration order. Listener changes apply next dispatch. **/
	public function dispatch(value:T)
	{
		for (listener in listeners.copy())
			listener(value);
	}

	/** Removes every listener. **/
	public function clear() listeners.resize(0);
}
