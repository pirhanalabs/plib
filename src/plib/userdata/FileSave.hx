package plib.userdata;

class SaveFile
{
	public final rootDir:String;
	public final jsName:String;

	public final userdata:UserData;
	public final profiles:UserProfiles;

	public function new(rootDir:String, jsName:String)
	{
		this.rootDir = rootDir;
		this.jsName = jsName;

		this.userdata = new UserData(rootDir, jsName);
		this.profiles = new UserProfiles(this);
	}

	public function init()
	{
		#if sys
		this.userdata.init();
		this.profiles.init();
		#end
	}
}