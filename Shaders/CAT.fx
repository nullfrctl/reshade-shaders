// SPDX-License-Identifier: GPL-3.0-or-later

#ifndef CAT_USE_CCT
#define CAT_USE_CCT 1
#endif

#include "CAT.fxh"
#if CAT_USE_CCT
#include "CCT.fxh"
#endif
#include "CSC.fxh"
#include "loathe.fxh"

namespace UI {
  uniform int std_illuminant_tooltip < ui_label = " ";
  ui_text = FORMAT("· A" NL
                   "  incandescent/tungsten;" NL
                       NL
                   "· B" NL
                   "  noon sunlight (obsolote);" NL
                       NL
                   "· C" NL
                   "  north sky daylight (obsolete);" NL
                       NL
                   "· D50" NL
                   "  horizon light;" NL
                       NL
                   "· D55" NL
                   "  mid- morning/afternoon daylight;" NL
                       NL
                   "· D65" NL
                   "  noon daylight---monitor;" NL
                       NL
                   "· D75" NL
                   "  north sky daylight;" NL
                       NL
                   "· E" NL
                   "  equal energy.");
  ui_type = "radio";
  ui_category = FORMAT("standard illuminant details");
  > = NULL;

  uniform int CAT_method < ui_label = " CAT method.";
  ui_type = "combo";
  ui_items = " · XYZ scaling\0 · von Kries\0 · Bradford\0";
  ui_spacing = THIN;
  ui_tooltip = FORMAT("the chromatic adaptation matrix or method." NL
                          NL
                      " 1. XYZ scaling is simplest, inaccurate;" NL
                      " 2. von Kries is an older method, accurate-ish;" NL
                      " 3. Bradford is most accurate and newest.");
  > = 2;

#define STD_ILLUMINANT_LIST " · A\0 · B\0 · C\0 · D50\0 · D55\0 · D65\0 · D75\0 · E\0 · custom\0"

  uniform int input_std_illuminant < ui_label = " input standard illuminant.";
  ui_type = "combo";
  ui_items = STD_ILLUMINANT_LIST;
  ui_spacing = THIN;
  > = 5;

  uniform int output_std_illuminant < ui_label = " output standard illuminant.";
  ui_type = "combo";
  ui_items = STD_ILLUMINANT_LIST;
  > = 5;

#if CAT_USE_CCT == 1
  uniform float custom_temperature < ui_label = " custom color temperature.";
  ui_step = 1.0;
#if CCT_ENFORCE_DOMAIN
  ui_min = CCT::CIE_D_domain.x;
  ui_max = CCT::CIE_D_domain.y;
#else
  ui_min = 0.0;
  ui_max = 1e+5;
#endif
  ui_max = 25000.0;
  ui_type = "drag";
  ui_tooltip = FORMAT("CCT in Kelvin to a whitepoint using CIE D");
  ui_spacing = THIN;
  > = CIE_1931::std_illuminants::D65_CCT;
#elif CAT_USE_CCT == 2
  uniform float custom_temperature < ui_label = " custom color temperature.";
  ui_step = 1.0;
#if CCT_ENFORCE_DOMAIN
  ui_min = CCT::CIE_D_domain.x;
  ui_max = CCT::CIE_D_domain.y;
#else
  ui_min = 0.0;
  ui_max = 1e+5;
#endif
  ui_type = "drag";
  ui_tooltip = FORMAT("CCT in Kelvin to a whitepoint using Kang et al. 2002");
  ui_spacing = THIN;
  > = CIE_1931::std_illuminants::D65_CCT;
#else
  uniform float2 custom_illuminant < ui_label = " custom illuminant.";
  ui_type = "drag";
  ui_step = 0.1;
  ui_min = 0.0;
  ui_max = 1e+5;
  > = CIE_1931::std_illuminants::D65 * 1e+4;
#endif
} // namespace UI

float2 get_std_illuminant(const int std_illuminant) {
  switch (std_illuminant) {
  case 0: // A
    return CIE_1931::std_illuminants::A;
  case 1: // B
    return CIE_1931::std_illuminants::B;
  case 2: // C
    return CIE_1931::std_illuminants::C;
  case 3: // D50
    return CIE_1931::std_illuminants::D50;
  case 4: // D55
    return CIE_1931::std_illuminants::D55;
  default: // D65
    return CIE_1931::std_illuminants::D65;
  case 6: // D75
    return CIE_1931::std_illuminants::D75;
  case 7: // E
    return CIE_1931::std_illuminants::E;
  case 8:
#if CAT_USE_CCT == 1
    return CCT::K_to_xy_CIE_D(UI::custom_temperature);
#elif CAT_USE_CCT == 2
    return CCT::K_to_xy_Kang2002(UI::custom_temperature);
#else
    return UI::custom_illuminant * 1e-4;
#endif
  }
}

float3 PS_CAT(std::VS_t VS) : SV_target {
  float3 color = tex2D(std::linear_backbuffer, VS.texcoord.xy).rgb;

  const float2 input_white = get_std_illuminant(UI::input_std_illuminant);
  const float2 output_white = get_std_illuminant(UI::output_std_illuminant);

  float3 XYZ = mul(CSC::matrices::BT_709_to_XYZ, color);

  if (UI::CAT_method == 0) {
    XYZ = CAT::XYZ_scaling(input_white, output_white, XYZ);
  } else if (UI::CAT_method == 1) {
    XYZ = CAT::von_Kries(input_white, output_white, XYZ);
  } else {
    XYZ = CAT::Bradford(input_white, output_white, XYZ);
  }

  color = mul(CSC::matrices::XYZ_to_BT_709, XYZ);

  return color;
}

technique CAT < ui_label = "loathe::CAT";
> {
  pass {
    PixelShader = PS_CAT;
    VertexShader = std::VS_quad;
    SRGBWriteEnable = true;
  }
}