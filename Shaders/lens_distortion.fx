// SPDX-License-Identifier: GPL-3.0-or-later

#include "gamma.fxh"
#include "loathe.fxh"

namespace loathe {
  namespace ui {
    uniform float k < ui_label = " lens distortion.";
    ui_category = "loathe::lens_distortion<gzdoom>";
    ui_type = "drag";
    > = -0.12;

    uniform float kcube < ui_label = " cubic distortion.";
    ui_category = "loathe::lens_distortion<gzdoom>";
    ui_type = "drag";
    > = 0.1;

    uniform float chromatic < ui_label = " chromatic aberration.";
    ui_category = "loathe::lens_distortion<gzdoom>";
    ui_type = "drag";
    ui_min = 1.0;
    > = 1.12;

    uniform float scale < ui_label = " scale.";
    ui_category = "loathe::lens_distortion<gzdoom>";
    ui_type = "drag";
    > = 1.0;
  } // namespace ui

  float get_scale(const float3 k, const float3 kcube) {
    float r2 = BUFFER_ASPECT_RATIO * BUFFER_ASPECT_RATIO * 0.25 + 0.25;
    float sqrt_r2 = sqrt(r2);
    float f0 = 1.0 + max(r2 * (k.r + kcube.r * sqrt_r2), 0.0);
    float f2 = 1.0 + max(r2 * (k.b + kcube.b * sqrt_r2), 0.0);
    float f = max(f0, f2);
    return rcp(f) * ui::scale;
  }

  float3 ps_gzdoom(std::vs_t vs) : sv_target {
    const float3 k = float3(ui::k, ui::k * ui::chromatic, ui::k * ui::chromatic * ui::chromatic);
    const float3 kcube = float3(ui::kcube, ui::kcube * ui::chromatic, ui::kcube * ui::chromatic * ui::chromatic);

    float2 position = vs.texcoord - 0.5;

    float2 p = position * float2(BUFFER_ASPECT_RATIO, 1.0);
    float r2 = dot(p, p);
    float3 f = 1.0 + r2 * (k + kcube * sqrt(r2));

    const float scale = get_scale(k, kcube);
    float3 x = f * position.x * scale + 0.5;
    float3 y = f * position.y * scale + 0.5;

    float3 color;
    color.r = tex2D(std::backbuffer, float2(x.r, y.r)).r;
    color.g = tex2D(std::backbuffer, float2(x.g, y.g)).g;
    color.b = tex2D(std::backbuffer, float2(x.b, y.b)).b;

    return color;
  }

  technique loathe_lens_distortion_gzdoom < ui_label = "loathe::lens_distortion<gzdoom>";
  > {
    pass {
      PixelShader = ps_gzdoom;
      VertexShader = std::vs_quad;
    }
  }
} // namespace loathe