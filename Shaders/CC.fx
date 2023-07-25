/* color correction (CC.fx): ACES-based color correction */

#if (__RESHADE__ < 50900)
#error "ReShade 5.9+ is required."
#endif

#include "TriDither.fxh"
#include "aces-hlsl/csc/ACEScct/ACEScsc.Academy.ACES_to_ACEScct.hlsl"
#include "aces-hlsl/csc/ACEScct/ACEScsc.Academy.ACEScct_to_ACES.hlsl"
#include "aces-hlsl/csc/ACEScg/ACEScsc.Academy.ACES_to_ACEScg.hlsl"
#include "aces-hlsl/csc/ACEScg/ACEScsc.Academy.ACEScg_to_ACES.hlsl"
#include "aces-hlsl/odt/sRGB/InvODT.Academy.sRGB_100nits_dim.hlsl"
#include "aces-hlsl/odt/sRGB/ODT.Academy.sRGB_100nits_dim.hlsl"
#include "aces-hlsl/rrt/InvRRT.hlsl"
#include "aces-hlsl/rrt/RRT.hlsl"
#include "stdlib.fxh"

#ifndef CC_LUT_ENABLED
#define CC_LUT_ENABLED 1
#endif

#define CC_LUT_SIZE 32

#if (CC_LUT_ENABLED)
texture3D CC_LUT_texture {
	Width = CC_LUT_SIZE;
	Height = CC_LUT_SIZE;
	Depth = CC_LUT_SIZE;
};

sampler3D CC_LUT { Texture = CC_LUT_texture; };

storage3D CC_LUT_storage {
	Texture = CC_LUT_texture;
	MipLevel = 0;
};
#endif

uniform int frame_count < source = "framecount";
> ;

namespace UI {
	uniform float exposure < ui_label = " Exposure";
	ui_units = " EV";
	ui_type = "drag";
	ui_step = 0.01;
	> = 0.0;

#define CATEGORY "ASC CDL"
	uniform float3 slope < ui_label = " Slope";
	ui_type = "color";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_category = CATEGORY;
	> = 0.5;

	uniform float3 offset < ui_label = " Offset";
	ui_type = "color";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_category = CATEGORY;
	> = 0.5;

	uniform float3 power < ui_label = " Power";
	ui_type = "color";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_category = CATEGORY;
	> = 0.5;

	uniform float saturation < ui_label = " Saturation";
	ui_min = 0.0;
	ui_type = "drag";
	ui_category = CATEGORY;
	ui_step = 0.01;
	ui_spacing = 2;
	> = 50.00;
#undef CATEGORY

#define CATEGORY "RGB mixer"
	uniform float3 R_mix < ui_label = " Red";
	ui_type = "color";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_category = CATEGORY;
	> = float3(0.5, 0.0, 0.0);

	uniform float3 G_mix < ui_label = " Green";
	ui_type = "color";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_category = CATEGORY;
	> = float3(0.0, 0.5, 0.0);

	uniform float3 B_mix < ui_label = " Blue";
	ui_type = "color";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_category = CATEGORY;
	> = float3(0.0, 0.0, 0.5);
#undef CATEGORY

#define CATEGORY "Contrast"
	uniform float pivot < ui_label = " Pivot";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_type = "drag";
	ui_category = CATEGORY;
	ui_tooltip = "this selects a mid-grey. ACES specifies 0.18 but other values are possible.";
	ui_step = 0.01;
	> = 0.18;

	uniform float contrast < ui_label = " Contrast";
	ui_min = 0.0;
	ui_type = "drag";
	ui_category = CATEGORY;
	ui_step = 0.01;
	> = 1.0;
#undef CATEGORY
} // namespace UI

float3 inverse_RRT(float3 OCES) {
	float3 rgbPost = mult_f3_f33(OCES, AP0_2_AP1_MAT);

	float3 rgbPre;
	rgbPre.r = segmented_spline_c5_rev(rgbPost.r);
	rgbPre.g = segmented_spline_c5_rev(rgbPost.g);
	rgbPre.b = segmented_spline_c5_rev(rgbPost.b);

	float3 ACES = mult_f3_f33(rgbPre, AP1_2_AP0_MAT);

	return ACES;
}

float3 forward_RRT(float3 ACES) {
	float3 rgbPre = mult_f3_f33(ACES, AP0_2_AP1_MAT);

	float3 rgbPost;
	rgbPost.r = segmented_spline_c5_fwd(rgbPre.r);
	rgbPost.g = segmented_spline_c5_fwd(rgbPre.g);
	rgbPost.b = segmented_spline_c5_fwd(rgbPre.b);

	float3 OCES = mult_f3_f33(rgbPost, AP1_2_AP0_MAT);

	return OCES;
}

float3 CC(float3 inputCV) {
	float3 OCES, ACES;

	OCES = InvODT_RGB_monitor(inputCV);
	ACES = inverse_RRT(OCES);

	/* exposure */
	{
		float3 ACEScg = ACES_to_ACEScg(ACES);
		ACEScg *= exp2(UI::exposure);
		ACES = ACEScg_to_ACES(ACEScg);
	}

	/* grading */
	{
		float3 ACEScct = ACES_to_ACEScct(ACES);

		/* RGB mixer */
		{
			const float3 R = UI::R_mix * 2.0;
			const float3 G = UI::G_mix * 2.0;
			const float3 B = UI::B_mix * 2.0;

			float src_Y = dot(ACEScct, AP1_RGB2Y);
			ACEScct = mul(ACEScct, float3x3(R, G, B));
			float des_Y = dot(ACEScct, AP1_RGB2Y);

			ACEScct = ACEScct - des_Y + src_Y;
		}

		/* ASC CDL */
		{
			/* CDL parameters */
			const float3 slope = UI::slope + 0.5;
			const float3 offset = UI::offset - 0.5;
			const float3 power = UI::power + 0.5;
			const float saturation = UI::saturation * 2 * 0.01;

			/* https://docs.acescentral.com/specifications/acescct/ */
			float3 slope_offset = ACEScct * slope + offset;
			ACEScct = slope_offset <= 0.0 ? slope_offset : pow(slope_offset, power);

			float luma = dot(ACEScct, float3(0.2126, 0.7152, 0.0722));

			// ACEScct = luma + saturation * (ACEScct - luma);
			ACEScct = lerp(luma, ACEScct, saturation);
		}

		/* contrast */
		{
			float middle_grey = lin_to_ACEScct(UI::pivot);
			ACEScct = lerp(middle_grey, ACEScct, UI::contrast);
		}

		ACES = ACEScct_to_ACES(ACEScct);
	}

	OCES = forward_RRT(ACES);

	return ODT_RGB_monitor(OCES);
}

#if CC_LUT_ENABLED
void CS_LUT(uint3 threadID : SV_dispatchthreadID) {
	// threadID.z = threadID.z * 2 + (frame_count % 2);

	if (any(threadID >= CC_LUT_SIZE))
		return;

	float3 color = threadID / (CC_LUT_SIZE - 1.0);

	color = CC(color);

	tex3Dstore(CC_LUT_storage, threadID, float4(color, 1.0));
}

float3 PS_apply(std::VS_t VS) : SV_target {
	float3 color;

	color = tex2D(std::back_buffer, VS.texcoord).rgb;
	color = tex3D(CC_LUT, color).rgb;

	return color;
}
#else
float3 PS_CC(std::VS_t VS) : SV_target {
	float3 color = tex2D(std::back_buffer, VS.texcoord).rgb;
	color = CC(color);

	return color;
}
#endif

technique CC < ui_label = "Color Correction";
> {
#if CC_LUT_ENABLED
	pass {
		ComputeShader = CS_LUT<8, 8, 8>;
		DispatchSizeX = 4;
		DispatchSizeY = 4;
		DispatchSizeZ = 4;
	}

	pass {
		PixelShader = PS_apply;
		VertexShader = std::VS_quad;
	}
#else
	pass {
		PixelShader = PS_CC;
		VertexShader = std::VS_quad;
	}
#endif
}