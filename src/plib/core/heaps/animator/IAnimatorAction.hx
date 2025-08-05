package core.heaps.animator;

interface IAnimatorAction
{
	var time(default, null):Float;
	var dir:Int;
	function start():Void;
	function update(r:Float):Void;
}
