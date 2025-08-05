package plib.engine;

interface IUpdateable
{
	function update(frame:engine.Frame):Void;
	function postupdate():Void;
	function isDisposed():Bool;
}
