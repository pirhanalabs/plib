package plib;

class Profiler
{
	public static function run(o:Dynamic, fn:haxe.Constraints.Function, ...args)
	{
		final timestamp = haxe.Timer.stamp();
		Reflect.callMethod(o, fn, args);
		final time = haxe.Timer.stamp() - timestamp;
		return {
			str: formatStr(time),
			raw: time,
		};
	}

	private static function formatStr(sec:Float):String
	{
		var ms = sec * 1000;
		var us = sec * 1_000_000;
		return '${M.pretty(sec, 6)}s |${M.pretty(ms, 3)}ms | ${M.pretty(us, 1)}µs';
	}
}
