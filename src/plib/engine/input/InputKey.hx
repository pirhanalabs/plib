package plib.engine.input;

/** Identity key for one game-defined input action. **/
class InputKey
{
	public final name:String;

	public function new(name:String)
	{
		if (name == null || StringTools.trim(name).length == 0)
			throw 'Input keys require a stable name.';
		this.name = name;
	}

	public inline function toString():String
		return name;
}
