package plib.utils;

class Seeder
{
	/**
		Pseudo-random seed from date and a random number.
	**/
	public static inline function fromDate()
	{
		var str = Date.now().toString() + '_' + Std.random(0x7ffffff);
		return haxe.crypto.Crc32.make(haxe.io.Bytes.ofString(str)) & 0x7ffffff;
	}

	/**
		Returns a seeded random for a x/y coord. Result range: [0->max[
	**/
	public static inline function fromCoords(seed:Int, x:Int, y:Int, max:Int)
	{
		var h = seed + x * 374761393 + y * 668265263; // all constants are prime
		h = (h ^ (h >> 13)) * 1274126177;
		return (h ^ (h >> 16)) % max;
	}
}
