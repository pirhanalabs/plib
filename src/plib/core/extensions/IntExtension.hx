package core.extensions;

class IntExtension{

    public static inline function clamp(me:Int, min:Int, max:Int)
    {
        return me < min ? min : me > max ? max : me;
    }

    public static inline function wrap(me:Int, min:Int, max:Int)
    {
        var range = max - min + 1;
        if (me < min)
            return me + Std.int(range * ((min - me) / range + 1)) - 1;
        return min + (me - min) % range;

    }
}