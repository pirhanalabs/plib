package plib.engine;

class AudioManager
{
	public var masterVolume(get, set):Float;
	public var musicVolume:Float = 1;
	public var soundVolume:Float = 1;

	private var music:hxd.snd.Channel;

	public function new() {}

	public function playMusic(music:hxd.res.Sound, loop = true)
	{
		if (this.music != null)
		{
			this.music.fadeTo(0, 0.5);

			var m = music.play(loop, 0);
			m.fadeTo(1, 0.5);
			this.music = m;
		}
		else
		{
			this.music = music.play(loop, 1);
		}

		if (loop == false)
		{
			this.music.onEnd = () ->
			{
				this.music = null;
			}
		}
	}

	public function playSound(sound:hxd.res.Sound, pitchVariance:Float = 0)
	{
		var channel = sound.play(false, 1);

		channel.addEffect(new hxd.snd.effect.Pitch(1 + MathTools.rand(-pitchVariance, pitchVariance)));
	}

	inline function get_masterVolume()
	{
		return hxd.snd.Manager.get().masterVolume;
	}

	inline function set_masterVolume(val:Float)
	{
		return hxd.snd.Manager.get().masterVolume = val;
	}
}
