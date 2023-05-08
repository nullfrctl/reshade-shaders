// SPDX-License-Identifier: CC-BY-NC-SA-4.0+

#include "loathe.fxh"

namespace ui
{

uniform float far_plane < __UNIFORM_DRAG_FLOAT1
  ui_label = "Far plane";
  ui_min = 0.0;
  ui_step = 1.0;
> = RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;

uniform float4 color < __UNIFORM_COLOR_FLOAT4
  ui_label = "Color";
> = float4(1.0, 1.0, 1.0, 1.0);

}

float3 ps_main(in loathe::vs_t vs): sv_target
{
  float3 color = tex2D(loathe::backbuffer, vs.texcoord.xy).rgb;
  color = EOTF(color);

  float depth = loathe::get_depth(vs, ui::far_plane);

  color = lerp(color, ui::color.rgb, depth.rrr * ui::color.a);

  color = OETF(color);
  return color;
}

technique loathe_fog <ui_label = "loathe: Fog";>
{
  pass
  {
    PixelShader = ps_main;
    VertexShader = loathe::vs_quad;
  }
}