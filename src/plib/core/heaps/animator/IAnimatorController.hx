package core.heaps.animator;

interface IAnimatorController
{
	function isFinished():Bool;
	function update(frame:engine.Frame):Void;
	function postupdate():Void;
}
