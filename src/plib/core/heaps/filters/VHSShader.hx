package core.heaps.filters;

class VHSShader extends h2d.filter.Shader<InternalShader>
{
	public var resolution_w(never, set):Int;
	public var resolution_h(never, set):Int;
	public var chromatic_abberation(get, set):Float;
	public var warp(get, set):Float;

	public var vignette_intensity(get, set):Float;
	public var vignette_opacity(get, set):Float;

	public var noise_speed(get, set):Float;
	public var noise_opacity(get, set):Float;

	public var pixelate(get, set):Bool;
	public var discolor(get, set):Bool;
	public var brightness(get, set):Float;

	public var grille_opacity(get, set):Float;
	public var scanline_opacity(get, set):Float;
	public var scanline_width(get, set):Float;

	public var resolutionOffsetX(never, set):Float;
	public var resolutionOffsetY(never, set):Float;
	public var resolutionAreaX(never, set):Float;
	public var resolutionAreaY(never, set):Float;

	public function new()
	{
		super(new InternalShader());
	}

	inline function set_resolutionAreaX(val:Float)
	{
		shader.resolutionArea.x = val;
		return val;
	}

	inline function set_resolutionAreaY(val:Float)
	{
		shader.resolutionArea.y = val;
		return val;
	}

	inline function set_resolutionOffsetX(val:Float)
	{
		shader.resolutionOffset.x = val;
		return val;
	}

	inline function set_resolutionOffsetY(val:Float)
	{
		shader.resolutionOffset.y = val;
		return val;
	}

	inline function get_scanline_width()
	{
		return shader.scanlines_width;
	}

	inline function set_scanline_width(val:Float)
	{
		shader.scanlines_width = val;
		return val;
	}

	inline function get_scanline_opacity()
	{
		return shader.scanlines_opacity;
	}

	inline function set_scanline_opacity(val:Float)
	{
		shader.scanlines_opacity = val;
		return val;
	}

	inline function get_grille_opacity()
	{
		return shader.grille_opacity;
	}

	inline function set_grille_opacity(val:Float)
	{
		shader.grille_opacity = val;
		return val;
	}

	inline function get_brightness()
	{
		return shader.brightness;
	}

	inline function set_brightness(val:Float)
	{
		shader.brightness = val;
		return val;
	}

	inline function get_discolor()
	{
		return shader.discolor == 1;
	}

	inline function set_discolor(val:Bool)
	{
		shader.discolor = val ? 1 : 0;
		return val;
	}

	inline function get_pixelate()
	{
		return shader.pixelate == 1;
	}

	inline function set_pixelate(val:Bool)
	{
		shader.pixelate = val ? 1 : 0;
		return val;
	}

	inline function get_noise_opacity()
	{
		return shader.noise_opacity;
	}

	inline function set_noise_opacity(val:Float)
	{
		shader.noise_opacity = val;
		return val;
	}

	inline function get_noise_speed()
	{
		return shader.noise_speed;
	}

	inline function set_noise_speed(val:Float)
	{
		shader.noise_speed = val;
		return val;
	}

	inline function get_vignette_intensity()
	{
		return shader.vignette_intensity;
	}

	inline function set_vignette_intensity(val:Float)
	{
		shader.vignette_intensity = val;
		return val;
	}

	inline function get_vignette_opacity()
	{
		return shader.vignette_opacity;
	}

	inline function set_vignette_opacity(val:Float)
	{
		shader.vignette_opacity = val;
		return val;
	}

	inline function set_resolution_w(val:Int)
	{
		shader.resolution.x = val;
		return val;
	}

	inline function set_resolution_h(val:Int)
	{
		shader.resolution.y = val;
		return val;
	}

	inline function set_chromatic_abberation(val:Float)
	{
		shader.abberation = val;
		return val;
	}

	inline function get_chromatic_abberation()
	{
		return shader.abberation;
	}

	inline function set_warp(val:Float)
	{
		shader.warp_amount = val;
		return val;
	}

	inline function get_warp()
	{
		return shader.warp_amount;
	}
}

private class InternalShader extends h3d.shader.ScreenShader
{
	static var SRC =
		{
			@global var time:Float;
			@param var texture:Sampler2D;
			@param var resolution:Vec2 = vec2(284, 216);
			@param var resolutionOffset:Vec2 = vec2(0, 0);
			@param var resolutionArea:Vec2 = vec2(1, 1);
			@param var warp_amount:Float = 0.5;
			@param var clip_warp:Int = 1;
			// vignette
			@param var vignette_intensity:Float = 0.4;
			@param var vignette_opacity:Float = 0.5;
			// roll
			@param var roll:Int = 1;
			@param var roll_speed:Float = 1.8;
			@param var roll_size:Float = 15.0;
			/**
				This value is not an exact science. 
				You have to play around with the value to find a look you like. 
				How this works is explained in the code below.
			**/
			@param var roll_variation:Float = 0.5;
			/**
				The distortion created by the rolling effect.
			**/
			@param var distort_intensity:Float = 0.025;
			// noise
			/**
				Positive values are down, negative are up
			**/
			@param var noise_speed:Float = 3.0;
			@param var noise_opacity:Float = 0.025;
			// mist
			/**
				fill each square ("pixel") with a sampled color, 
				creating a pixel look and more accurate representation of how a crt monitor would look.
			**/
			@param var pixelate:Int = 0;
			@param var abberation:Float = 0.01;
			@param var brightness:Float = 1.3;
			@param var discolor:Int = 1;
			@param var grille_opacity:Float = 0.2;
			@param var scanlines_opacity:Float = 0.4;
			@param var scanlines_width:Float = 0.25;
			/**
				Used by the noise function to generate a
				pseudo-random value between 0.0 and 1.0
			**/
			function random(uv:Vec2):Vec2
			{
				uv = vec2(dot(uv, vec2(127.1, 311.7)), dot(uv, vec2(269.5, 183.3)));
				return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
			}
			/**
				Generate a perlin noise used by the distortion effects
			**/
			function noise(uv:Vec2):Float
			{
				var uv_index:Vec2 = floor(uv);
				var uv_fract:Vec2 = fract(uv);
				var blur:Vec2 = smoothstep(0.0, 1.0, uv_fract);
				return mix(mix(dot(random(uv_index + vec2(0.0, 0.0)), uv_fract - vec2(0.0, 0.0)),
					dot(random(uv_index + vec2(1.0, 0.0)), uv_fract - vec2(1.0, 0.0)), blur.x),
					mix(dot(random(uv_index + vec2(0.0, 1.0)), uv_fract - vec2(0.0, 1.0)), dot(random(uv_index + vec2(1.0, 1.0)), uv_fract - vec2(1.0, 1.0)),
						blur.x),
					blur.y) * 0.5
					+ 0.5;
			}
			/**
				Takes in the uv and warps the edges, creating the spherized effect.
			**/
			function warp(uv:Vec2):Vec2
			{
				var delta:Vec2 = uv - 0.5;
				var delta2:Float = dot(delta.xy, delta.xy);
				var delta4:Float = delta2 * delta2;
				var delta_offset = delta4 * warp_amount;
				return uv + delta * delta_offset;
			}
			/**
				Adds a black border to hide stretched pixels created by the warp effect.
			**/
			function border(uv:Vec2):Float
			{
				var radius:Float = min(warp_amount, 0.01);

				radius = max(min(min(abs(radius * 2.0), abs(1.0)), abs(1.0)), 1e-5);
				var abs_uv:Vec2 = abs(uv * 2.0 - 1.0) - vec2(1.0, 1.0) + radius;
				var dist:Float = length(max(vec2(0.0), abs_uv)) / radius;
				var square:Float = smoothstep(0.96, 1.0, dist);
				return clamp(1.0 - square, 0.0, 1.0);
			}
			/**
				Adds a vignette shadow to the edges of the image.
			**/
			function vignette(uv:Vec2):Float
			{
				uv *= 1.0 - uv.xy;
				var vignette:Float = uv.x * uv.y * 15.0;
				return pow(vignette, vignette_intensity * vignette_opacity);
			}
			function curve(uv:Vec2):Vec2
			{
				var out = uv * 2 - 1;

				var offset = abs(out.yx) / vec2(3.0, 3.0);
				out = out + out * offset * offset;

				out = out * 0.5 + 0.5;
				return out;
			}
			/**
				Fragment shader
			**/
			function fragment()
			{
				var relativeUV = (input.uv - resolutionOffset) / resolutionArea;
				relativeUV = clamp(relativeUV, 0.0, 1.0);

				// var uv:Vec2 = warp(input.uv);
				var uv:Vec2 = warp(relativeUV);
				var text_uv:Vec2 = uv; // this one needs to stay input.uv.
				var roll_uv:Vec2 = vec2(0, 0);

				var t:Float = 0.0;

				if (roll == 1)
				{
					t = time;
				}

				if (pixelate == 1)
				{
					text_uv = ceil(uv * resolution) / resolution;
				}

				var roll_line:Float = 0.0;
				if ((roll == 1 || noise_opacity > 0.0))
				{
					roll_line = smoothstep(0.8, 0.9, sin(uv.y * roll_size - (t * roll_speed)));
					roll_line *= roll_line * smoothstep(0.3, 0.9, sin(uv.y * roll_size * roll_variation - (t * roll_speed * roll_variation)));
					roll_uv = vec2(roll_line * distort_intensity * (1.0 - input.uv.x) * 0.15, 0.0);
				}

				var text:Vec4 = vec4(0.0, 0.0, 0.0, 0.0);
				if (roll == 1)
				{
					text = texture.get(relativeUV);
					text.r = texture.get(text_uv + roll_uv * 0.8 + vec2(abberation, 0.0) * 0.1).r;
					text.g = texture.get(text_uv + roll_uv * 1.2 - vec2(abberation, 0.0) * 0.1).g;
					text.b = texture.get(text_uv + roll_uv).b;
				}
				else
				{
					text.r = texture.get(text_uv + vec2(abberation, 0.0) * 0.1).r;
					text.g = texture.get(text_uv - vec2(abberation, 0.0) * 0.1).g;
					text.b = texture.get(text_uv).b;
				}

				var r:Float = text.r;
				var g:Float = text.g;
				var b:Float = text.b;

				uv = warp(relativeUV);

				if (grille_opacity > 0.0)
				{
					var g_r:Float = smoothstep(0.85, 0.95, abs(sin(uv.x * (resolution.x * 3.14159265))));
					var g_g:Float = smoothstep(0.85, 0.95, abs(sin(1.05 + uv.x * (resolution.x * 3.14159265))));
					var g_b:Float = smoothstep(0.85, 0.95, abs(sin(2.1 + uv.x * (resolution.x * 3.14159265))));

					r = mix(r, r * g_r, grille_opacity);
					g = mix(g, g * g_g, grille_opacity);
					b = mix(b, b * g_b, grille_opacity);
				}

				text.r = clamp(r * brightness, 0.0, 1.0);
				text.g = clamp(g * brightness, 0.0, 1.0);
				text.b = clamp(b * brightness, 0.0, 1.0);

				var scanlines:Float = 0.5;
				if (scanlines_opacity > 0.0)
				{
					var pixel_y = uv.y * resolution.y;
					var scanline_pattern = 0.5 + 0.5 * abs(sin(pixel_y * 3.15159265));
					scanline_pattern = pow(scanline_pattern, 4.0);
					text.rgb = mix(text.rgb, text.rgb * scanline_pattern, scanlines_opacity);

					// this is the original, distorted scanlines
					// scanlines = smoothstep(scanlines_width, scanlines_width + 0.5, abs(sin(uv.y * (resolution.y * 3.14159265))));
					// text.rgb = mix(text.rgb, text.rgb * vec3(scanlines), scanlines_opacity);
				}

				if (noise_opacity > 0.0)
				{ //
					var n:Float = smoothstep(0.4, 0.5, noise(uv * vec2(2.0, 200.0) + vec2(10.0, (t * (noise_speed)))));
					roll_line *= n * scanlines * clamp(random((ceil(uv * resolution) / resolution) + vec2(t * 0.8, 0.0)).x + 0.8, 0.0, 1.0);
					text.rgb = clamp(mix(text.rgb, text.rgb + r, noise_opacity), vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
				}

				var static_noise_intensity:Float = 0.06;

				if (static_noise_intensity > 0.0 && noise_opacity > 0.0)
				{
					text.rgb += clamp(random((ceil(uv * resolution) / resolution) + fract(t)).x, 0.0, 1.0) * static_noise_intensity;
				}

				text.rgb *= border(uv);
				text.rgb *= vignette(uv);

				if (clip_warp == 1)
				{
					text.a = texture.get(input.uv).a * border(uv);
				}

				var saturation:Float = 0.35;
				var contrast:Float = 1.55;

				if (discolor == 1)
				{
					// saturation
					var greyscale:Vec3 = vec3(text.r + text.g + text.b) / 3;
					text.rgb = mix(text.rgb, greyscale, saturation);
					// contrast
					var midpoint:Float = pow(0.5, 2.2);
					text.rgb = (text.rgb - vec3(midpoint)) * contrast + midpoint;
				}

				pixelColor = text;
			}
		}
}
