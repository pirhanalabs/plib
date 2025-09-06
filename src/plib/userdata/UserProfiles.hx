package plib.userdata;

class UserProfiles
{
	public final savefile:SaveFile;
	public final profiles:Map<String, UserProfile>;

	public function new(savefile:SaveFile)
	{
		this.savefile = savefile;
		this.profiles = [];
	}

	public function init()
	{
		savefile.userdata.createDirectory('profiles');
		final loadResult = this.savefile.userdata.load('profiles/settings.json');
		switch (loadResult)
		{
			case SuccessContent(data):
			case _:
				final jsonString = haxe.Json.stringify({profiles: []});
				this.savefile.userdata.save('profiles/settings.json', jsonString);
		}
	}

	public function getProfile(id:String)
	{
		// lazy loader
		if (!profiles.exists(id))
		{
			final profile = new UserProfile(this, id);
			profile.init();
			this.profiles.set(id, profile);
			save();
		}
		return this.profiles.get(id);
	}

	public function save()
	{
		final struct = {
			profiles: [for (key => _ in profiles) key]
		};

		final jsonString = haxe.Json.stringify(struct);
		this.savefile.userdata.save('profiles/settings.json', jsonString);
	}
}