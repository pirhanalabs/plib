package plib.heaps.nav;

interface INavigationInstance
{
	// navigation manager reference
	var navigation:NavigationManager;

	// x and y positions
	var x(default, set):Float;
	var y(default, set):Float;

	// focus
	function focus():Void;
	function unfocus():Void;

	// mouse interactions
	function disableInteractive():Void;
	function enableInteractive():Void;

	function isDisabled():Bool;

	// callback
	function execute():Void;
}
