/* color correction (CC.fx): ACES-based color correction */

#if (__RESHADE__ < 50900)
#error "ReShade 5.9+ is required."
#endif

#include "stdlib.fxh"

namespace textures {
	texture1D sRGB_to_linear < source = "sRGB_to_linear.dds";
	> {
		Width = 1;
		Format = R8;
	};

	texture1D linear_to_sRGB < source = "linear_to_sRGB.dds";
	> {
		Width = 1;
		Format = R8;
	};
} // namespace textures

sampler1D sRGB_to_linear { Texture = textures::sRGB_to_linear; };

sampler1D linear_to_sRGB { Texture = textures::linear_to_sRGB; };

float3 PS_gamma(std::VS_t VS) : SV_target {
	float3 color;

	color = tex2D(std::back_buffer, VS.texcoord).rgb;
	color.r = tex1D(sRGB_to_linear, color.r);
	color.g = tex1D(sRGB_to_linear, color.g);
	color.b = tex1D(sRGB_to_linear, color.b);

	return color;
}

technique gamma < ui_label = "Gamma";
> {
	pass {
		PixelShader = PS_gamma;
		VertexShader = std::VS_quad;
	}
}