package plib.userdata;

class UserData
{
	public final rootDir:String;
	public final jsName:String;

	public function new(rootDir:String, jsName:String)
	{
		this.rootDir = rootDir;
		this.jsName = jsName;
	}

	public function init()
	{
		createDirectory("");
	}

	private function validate(path:String):UserDataResult
	{
		#if (!sys && !js)
		return NotSupported;
		#end

		#if js
		var storage = js.Browser.getLocalStorage();
		if (storage == null)
		{
			return BrowserNotEnabled;
		}
		#end
		return Success;
	}

	public function exists(path:String):Bool
	{
		var valid = validate(path);
		if (valid != Success)
		{
			return false;
		}

		#if sys
		return sys.FileSystem.exists(getSysPath(path));
		#end

		#if js
		var storage = js.Browser.getLocalStorage();
		var content = storage.getItem(getJsPath(path));
		return content != null;
		#end

		return false;
	}

	/**
		Load data from a path.
	**/
	public function load(path:String)
	{
		var valid = validate(path);
		if (valid != Success)
		{
			return valid;
		}

		if (!exists(path))
		{
			return Failure;
		}

		#if sys
		var content = sys.io.File.getContent(getSysPath(path));
		return SuccessContent(content);
		#end

		#if js
		var storage = js.Browser.getLocalStorage();
		var content = storage.getItem(getJsPath(path));
		return SuccessContent(content);
		#end

		return NotSupported;
	}

	public function save(path:String, data:String):UserDataResult
	{
		var valid = validate(path);
		if (valid != Success)
		{
			return valid;
		}

		#if sys
		// if sys, we will need to put all these data in a specific folder.
		// i.e. in Mac, it may be in Documents
		// for now we will put it in a data folder in the same directory as the runtime.
		path = getSysPath(path);
		#end

		var p = new haxe.io.Path(path);
		var d = p.dir;
		var f = p.file;

		// create a directory if none
		#if sys
		if (!sys.FileSystem.exists(d))
		{
			sys.FileSystem.createDirectory(d);
		}
		#end

		#if sys
		sys.io.File.saveContent(path, data);
		return Success;
		#elseif js
		var storage = js.Browser.getLocalStorage();
		storage.setItem(getJsPath(path), data);
		return Success;
		#end
		return NotSupported;
	}

	/**
		Get the system path
	**/
	inline function getSysPath(path:String)
	{
		return '${rootDir}/${path}';
	}

	/**
		Get the js path
	**/
	inline function getJsPath(path:String)
	{
		return '${jsName}/${path}}';
	}

	/**
		Creates a new directory.
	**/
	public function createDirectory(path:String)
	{
		#if sys
		final actualPath = [this.rootDir, path];
		final actualPathString = haxe.io.Path.join(actualPath);
		if (!sys.FileSystem.exists(actualPathString))
		{
			sys.FileSystem.createDirectory(actualPathString);
		}
		#end
	}

	/**
		Deletes a directory.
	**/
	public function deleteDirectory(path:String)
	{
		#if sys
		final actualPath = [this.rootDir, path];
		final actualPathString = haxe.io.Path.join(actualPath);
		if (sys.FileSystem.exists(actualPathString))
		{
			sys.FileSystem.deleteDirectory(actualPathString);
		}
		#end
	}

	/**
		Deletes a file.
	**/
	public function deleteFile(path:String)
	{
		var valid = validate(path);
		if (valid != Success)
		{
			return valid;
		}

		if (!exists(path))
		{
			return Failure;
		}

		#if sys
		sys.FileSystem.deleteFile(getSysPath(path));
		return Success;
		#elseif js
		final storage = js.Browser.getLocalStorage();
		storage.removeItem(getJsPath(path));
		return Success;
		#end

		return NotSupported;
	}
}