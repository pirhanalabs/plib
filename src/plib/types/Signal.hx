package plib.types;

/** 
	Disposable handle returned by `Signal.listen()`. 
**/
class SignalSubscription
{
	private var disposeCallback:Null<Void->Void>;

	@:allow(plib.types.Signal)
	private function new(callback:Void->Void)
	{
		disposeCallback = callback;
	}

	/** 
		Detaches the listener once; subsequent calls do nothing. 
	**/
	public function dispose()
	{
		if (disposeCallback == null)
			return;
		var callback = disposeCallback;
		disposeCallback = null;
		callback();
	}
}

private typedef SignalListener<T> =
{
	var cb:T->Void;
	var active:Bool;
}

/** 
	Small synchronous signal with disposable listeners. 
**/
class Signal<T>
{
	private final listeners:Array<SignalListener<T>> = [];

	/** 
		Creates a signal with no listeners. 
	**/
	public function new() {}

	/** 
		Registers a synchronous listener and returns its disposal handle. 
	**/
	public function listen(listener:T->Void):SignalSubscription
	{
		if (listener == null)
			throw 'Input signal listener cannot be null.';

		var entry:SignalListener<T> = {cb: listener, active: true};
		listeners.push(entry);
		return new SignalSubscription(() -> listeners.remove(entry));
	}

	/**
		Removes a listener by its callback.
	**/
	public function remove(listener:T->Void):Void
	{
		var i = listeners.length;

		while (i > 0)
		{
			i--;

			var entry = listeners[i];
			if (Reflect.compareMethods(entry.cb, listener))
			{
				entry.active = false;
				listeners.splice(i, 1);
			}
		}
	}

	/** 
		Calls a snapshot of listeners in registration order. Listener changes apply next dispatch. 
	**/
	public function dispatch(value:T)
	{
		for (entry in listeners.copy())
		{
			if (entry.active)
			{
				entry.cb(value);
			}
		}
	}

	/** 
		Removes every listener. 
	**/
	public function clear()
	{
		for (entry in listeners)
		{
			entry.active = false;
		}

		listeners.resize(0);
	}
}
