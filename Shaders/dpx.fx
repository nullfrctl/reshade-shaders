// SPDX-License-Identifier: CC-BY-NC-SA-4.0+
#include "gamma.fxh"
#include "loathe.fxh"
#include "log.fxh"

namespace loathe {
  namespace ui {
    uniform int black_offset < ui_label = " black offset.";
    ui_type = "combo";
    ui_items = " Off\0 On\0";
    ui_category = "loathe::dpx";
    > = true;

    uniform float exposure < ui_label = " exposure.";
    ui_type = "drag";
    ui_category = "loathe::dpx";
    > = 0.0;
    
    uniform int luma_method < ui_label = " luma derivation.";
    ui_spacing = 3;
    ui_items = " dot\0 max\0";
    ui_type = "combo";
    ui_category = "loathe::dpx";
    > = 0;

    uniform float saturation < ui_label = " saturation.";
    ui_type = "drag";
    ui_min = 0.0;
    ui_category = "loathe::dpx";
    > = 1.0;
    
    uniform float contrast < ui_label = " contrast.";
    ui_spacing = 3;
    ui_type = "drag";
    ui_min = 0.0;
    ui_category = "loathe::dpx";
    > = 1;
    
    uniform float pivot < ui_label = " pivot.";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_category = "loathe::dpx";
    > = 0.435;
  } // namespace ui

  float3 rgb_chromaticity(const float3 RGB) {
    const float denominator = rcp(dot(RGB, 1.0));
    return (RGB*denominator);
  }
  
  float3 saturation(const float3 color, const float saturation, const int luma_mode) {
    [branch] switch(luma_mode) {
      default: // dot
        return lerp(dot(color, float3(0.2126, 0.7152, 0.0722)), color, saturation);
      case 3: // max
        return lerp(max(color), color, saturation);
      /*
      case 2: // min
        return lerp(min(color.r, min(color.g, color.b)), color, saturation);
      */
    }
  }

  float3 ps_main(vs_t vs) : sv_target {
    float3 color = tex2D(backbuffer, vs.texcoord.xy).rgb;
    color = gamma::signal_to_linear(color);
    color *= exp2(ui::exposure);
    
    color = log::cineon::encode(color);
    
    color = lerp(ui::pivot, color, ui::contrast);
    //color = lerp(max(color), color, ui::saturation);
    color = saturation(color, ui::saturation, ui::luma_method);

    [branch] if (ui::black_offset) {
      color = log::cineon::decode(color);
    }
    else {
      color = log::cineon::decode(color, NULL);
      color = linearstep(log::cineon::_black_offset, 1.0, color);
    }

    color = gamma::linear_to_signal(color);
    
    return color;
  }

  technique loathe_dpx < ui_label = "loathe::dpx";
  > {
    pass {
      PixelShader = ps_main;
      VertexShader = vs_quad;
    }
  }
} // namespace loathe