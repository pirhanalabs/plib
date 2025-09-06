package plib.userdata;

class UserProfile
{
	public final id:String;
	public final profiles:UserProfiles;

	public function new(profiles:UserProfiles, id:String)
	{
		this.id = id;
		this.profiles = profiles;
	}

	public function init()
	{
		this.profiles.savefile.userdata.createDirectory(haxe.io.Path.join(['profiles', id]));
	}

	public function save(path:String, data:String):UserDataResult
	{
		return this.profiles.savefile.userdata.save(getPath(path), data);
	}

	public function load(path:String):UserDataResult
	{
		return this.profiles.savefile.userdata.load(getPath(path));
	}

	public function exists(path:String):Bool
	{
		return this.profiles.savefile.userdata.exists(getPath(path));
	}

	public function createDirectory(path:String)
	{
		return this.profiles.savefile.userdata.createDirectory(getPath(path));
	}

	public function deleteDirectory(path:String)
	{
		return this.profiles.savefile.userdata.deleteDirectory(getPath(path));
	}

	public function deleteFile(path:String)
	{
		return this.profiles.savefile.userdata.deleteFile(getPath(path));
	}

	inline function getPath(path:String)
	{
		return haxe.io.Path.join(['profiles', this.id, path]);
	}

	public function loadJson(path:String):UserDataResult
	{
		final result = load(path);
		switch (result)
		{
			case SuccessContent(data):
				try
				{
					final json = haxe.Json.parse(data);
					return SuccessContent(json);
				}
				catch (e)
				{
					return FailureReason('parse-error', getPath(path) + ': Failed to parse data.');
				}
			case _:
				return result;
		}
	}
}