// SPDX-License-Identifier: GPL-3.0-or-later

#ifndef LOATHE_CAT_USE_CCT
#define LOATHE_CAT_USE_CCT 1
#endif

#include "CAT.fxh"
#if LOATHE_CAT_USE_CCT
#include "CCT.fxh"
#endif
#include "CSC.fxh"
#include "gamma.fxh"
#include "loathe.fxh"

namespace loathe {
  namespace ui {
    uniform int std_illuminant < ui_label = " standard illuminant.";
    ui_items = " A\0 B\0 C\0 D50\0 D55\0 D65\0 D75\0 D93\0 E\0 custom\0";
    ui_type = "combo";
    > = 5;

#if LOATHE_CAT_USE_CCT == 1
    uniform float custom_temperature < ui_label = " custom color temperature.";
    ui_step = 1.0;
    ui_min = 4000.0;
    ui_max = 25000.0;
    ui_type = "drag";
    > = CIE_1931::std_illuminants::D65_CCT;
#elif LOATHE_CAT_USE_CCT == 2
    uniform float custom_temperature < ui_label = " custom color temperature.";
    ui_step = 1.0;
    ui_min = 1667.0;
    ui_max = 25000.0;
    ui_type = "drag";
    > = CIE_1931::std_illuminants::D65_CCT;
#else
    uniform float2 custom_illuminant < ui_label = " custom illuminant.";
    ui_type = "drag";
    ui_step = 0.1;
    ui_min = 0.0;
    ui_max = 1e+5;
    > = CIE_1931::std_illuminants::D65 * 1e+4;
#endif
  } // namespace ui

  float2 get_std_illuminant() {
    switch (ui::std_illuminant) {
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
    case 7: // D93
      return CIE_1931::std_illuminants::D93;
    case 8: // E
      return CIE_1931::std_illuminants::E;
    case 9:
#if LOATHE_CAT_USE_CCT == 1
      return CCT::K_to_xy_CIE_D(ui::custom_temperature);
#elif LOATHE_CAT_USE_CCT == 2
      return CCT::K_to_xy_Kang2002(ui::custom_temperature);
#else
      return ui::custom_illuminant * 1e-4;
#endif
    }
  }

  float3 ps_CAT(std::vs_t vs) : sv_target {
    float3 color = tex2D(std::backbuffer, vs.texcoord.xy).rgb;
    color = gamma::signal_to_linear(color);

    float3 XYZ = mul(CSC::matrices::BT_709_to_XYZ, color);
    XYZ = CAT::Bradford(CIE_1931::std_illuminants::D65, get_std_illuminant(), XYZ);
    color = mul(CSC::matrices::XYZ_to_BT_709, XYZ);

    color = gamma::linear_to_signal(color);

    return color;
  }

  technique color < ui_label = "loathe::CAT";
  > {
    pass {
      PixelShader = ps_CAT;
      VertexShader = std::vs_quad;
    }
  }
} // namespace loathe