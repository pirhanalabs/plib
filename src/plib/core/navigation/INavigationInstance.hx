package core.navigation;

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

	// callback
	function execute():Void;
}
