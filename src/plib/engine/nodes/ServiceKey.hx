package plib.engine.nodes;

/** Type-safe identity used to register and retrieve optional project services from a tree. **/
class ServiceKey<T:Node>
{
	public final name:String;

	/** Creates a unique key whose name is used only for diagnostics. Keep one static instance. **/
	public function new(name:String)
	{
		this.name = name;
	}

	/** Returns the diagnostic service name. **/
	public function toString()
	{
		return name;
	}
}
