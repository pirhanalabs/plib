package core.heaps.filters;

class InvertFilter extends h2d.filter.Shader<InternalShader>
{
	public var ratio(get, set):Float;

	public function new()
	{
		super(new InternalShader());
	}

	inline function get_ratio():Float
	{
		return shader.ratio;
	}

	inline function set_ratio(val:Float)
	{
		var v = val;
		if (v > 1)
		{
			v = 1;
		}
		if (v < 0)
		{
			v = 0;
		}
		return shader.ratio = val;
	}
}

// --- Shader -------------------------------------------------------------------------------
private class InternalShader extends h3d.shader.ScreenShader
{
	static var SRC =
		{
			@param var ratio:Float = 1;
			@param var texture:Sampler2D;
			/** lerp values **/
			function lerp(min:Float, max:Float, val:Float):Float
			{
				return min * (1.0 - val) + (max * val);
			}
			/** fragment shader **/
			function fragment()
			{
				var col = texture.get(input.uv);
				col.r = lerp(col.r, 1 - col.r, ratio);
				col.g = lerp(col.g, 1 - col.g, ratio);
				col.b = lerp(col.b, 1 - col.b, ratio);
				col.rgb *= col.a;
				output.color = col;
			}
		};
}
