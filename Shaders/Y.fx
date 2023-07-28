/* luminance (Y.fx):  ramp based effects. */

#if (__RESHADE__ < 50900)
#error "ReShade 5.9+ is required."
#endif

#include "TriDither.fxh"
#include "stdlib.fxh"

#define RAMP_SIZE 256

namespace UI {
	uniform float gamma < ui_label = " Gamma";
	ui_type = "drag";
	> = 1.0;
} // namespace UI

namespace textures {
	texture2D Y_ramp {
		Width = RAMP_SIZE;
		Height = 1;
		Format = R8;
	};
} // namespace textures

sampler2D Y_ramp { Texture = textures::Y_ramp; };

float modify(float Y) {
	Y = pow(Y, 2.2);
	Y = pow(Y, UI::gamma);
	Y = pow(Y, rcp(2.2));

	return Y;
}

float PS_ramp(std::VS_t VS) : SV_target {
	float Y = VS.texcoord.x;
	Y = modify(Y);
	return Y;
}

/*
float3 tex1D_as_3D(sampler1D T, float3 C) {
  C.x = tex1D(T, C.x).x;
  C.y = tex1D(T, C.y).x;
  C.z = tex1D(T, C.z).x;

  return C;
}
*/

float3 PS_apply(std::VS_t VS) : SV_target {
	float3 color;

	color = tex2D(std::back_buffer, VS.texcoord).rgb;
	color.r = tex2D(Y_ramp, color.r).r;
	color.g = tex2D(Y_ramp, color.g).r;
	color.b = tex2D(Y_ramp, color.b).r;

	return color;
}

technique Y < ui_label = "Luminance";
> {
	pass {
		PixelShader = PS_ramp;
		VertexShader = std::VS_quad;
		RenderTarget = textures::Y_ramp;
	}

	pass {
		PixelShader = PS_apply;
		VertexShader = std::VS_quad;
	}
}