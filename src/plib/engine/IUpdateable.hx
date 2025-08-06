package plib.engine;

interface IUpdateable
{
	function update(frame:plib.engine.Frame):Void;
	function postupdate():Void;
	function isDisposed():Bool;
}
