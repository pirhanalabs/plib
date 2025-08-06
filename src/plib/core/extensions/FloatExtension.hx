package plib.core.extensions;

class FloatExtension{


    public static inline function int(me:Float){
        return Math.floor(me);
    }

    public static inline function pretty(me:Float, precision:Int = 2){
        if (precision == 0)
            return Math.round(me);
        final d = Math.pow(10, precision);
        return Math.round(me * d) / d;
    }
}