package plib;

class Globals{

    private static final values:Map<String, Dynamic> = new Map();

    /**
        Sets a global variable.
    **/
    public static function set(id:String, val:T){
        Globals.values.set(id, val);
    }

    /**
        Gets a global variable.
    **/
    public static function get<T>(id:String):T{
        return Globals.values.get(id);
    }

    /**
        Returns if the global variable exists.
    **/
    public static function has(id:String){
        return Globals.values.exists(id);
    }
}