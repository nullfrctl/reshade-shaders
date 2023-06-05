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
  } // namespace ui

  float3 ps_main(vs_t vs) : sv_target {
    float3 color = tex2D(backbuffer, vs.texcoord.xy).rgb;
    color = gamma::signal_to_linear(color);
    color = log::cineon::encode(color);

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