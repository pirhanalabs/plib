package plib.common.messages;

/**
	Simple Message dispatcher.

	  Can use singleton instance or make regular instances.
**/
class MessageBus
{
	private static var instance:MessageBus;

	/**
		Get the singleton instance
	**/
	public static function get()
	{
		if (instance == null)
		{
			instance = new MessageBus();
		}
		return instance;
	}

	private var listeners:Map<Class<IMessage>, Array<IMessage->Void>>;

	/**
		Simple Message Dispatcher
	**/
	public function new()
	{
		listeners = [];
	}

	/**
		Add a message listener
	**/
	public function on<T:IMessage>(c:Class<T>, fn:T->Void)
	{
		if (!listeners.exists(c))
		{
			listeners.set(c, [fn]);
			return;
		}
		listeners.get(c).push(fn);
	}

	/**
		Remove a message listener
	**/
	public function remove<T:IMessage>(c:Class<T>, fn:T->Void)
	{
		if (!listeners.exists(c))
			return false;

		return listeners.get(c).remove(fn);
	}

	/**
		Remove all event listeners
	**/
	public function clear()
	{
		instance = [];
	}

	/**
		Emit an event
	**/
	public function emit<T:IMessage>(data:T)
	{
		var c = Type.getClass(data);
		for (fn in (listeners.get(c) ?? []))
		{
			cast(fn : T->Void)(data);
		}
	}
}
