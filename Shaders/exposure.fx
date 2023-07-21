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

namespace UI {
	uniform float exposure < ui_label = "exposure.";
	ui_type = "drag";
	> = 0.0;

	uniform float3 slope < ui_label = "slope.";
	ui_type = "color";
	ui_min = 0.0;
	ui_max = 1.0;
	> = 0.495;

	uniform float3 offset < ui_label = "offset.";
	ui_type = "color";
	ui_min = 0.0;
	ui_max = 1.0;
	> = 0.505;

	uniform float3 power < ui_label = "power.";
	ui_type = "color";
	ui_min = 0.0;
	ui_max = 1.0;
	> = 0.490;

	uniform float saturation < ui_label = "saturation.";
	ui_min = 0.0;
	ui_type = "drag";
	> = 1.0;

	uniform float contrast < ui_label = "contrast.";
	ui_min = 0.0;
	ui_type = "drag";
	> = 1.0;

	uniform float pivot < ui_label = "pivot.";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_type = "drag";
	> = 0.5;
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

float3 PS_exposure(std::VS_t VS) : SV_target {
	float3 outputCV, OCES, ACES;

	outputCV = tex2D(std::back_buffer, VS.texcoord).rgb;
	outputCV += TriDither(outputCV, VS.texcoord, 8);

	OCES = InvODT_RGB_monitor(outputCV);
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

		/* ASC CDL */
		{
			/* CDL parameters */
			const float3 slope = UI::slope + 0.5;
			const float3 offset = UI::offset - 0.5;
			const float3 power = UI::power + 0.5;

			/* https://docs.acescentral.com/specifications/acescct/ */
			float3 slope_offset = ACEScct * slope + offset;
			ACEScct = slope_offset <= 0.0 ? slope_offset : pow(slope_offset, power);

			float luma = dot(ACEScct, float3(0.2126, 0.7152, 0.0722));
			ACEScct = lerp(luma, ACEScct, UI::saturation);
		}

		/* contrast */
		{
			float middle_grey = lin_to_ACEScct(UI::pivot);
			ACEScct = lerp(middle_grey, ACEScct, UI::contrast);
		}

		ACES = ACEScct_to_ACES(ACEScct);
	}

	// ACES = mult_f3_f33(ACES, blue_light_fix);

	OCES = forward_RRT(ACES);
	outputCV = ODT_RGB_monitor(OCES);

	outputCV += TriDither(outputCV, VS.texcoord, 8);
	return outputCV;
}

technique exposure < ui_label = "exposure.";
> {
	pass {
		PixelShader = PS_exposure;
		VertexShader = std::VS_quad;
	}
}