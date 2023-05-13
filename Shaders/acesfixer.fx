// SPDX-License-Identifier: CC-BY-NC-SA-4.0+
#pragma once
#include "loathe.fxh"
#include "gamma.fxh"

namespace loathe
{
  texture2D lut_texture <source = "aces_atlas.png"; pooled = true;> 
  {
    Width = 1024;
    Height = 64;
    Format = RGBA8;
  };

  sampler2D lut
  {
    Texture = lut_texture;
  };

  namespace ui
  {
    uniform float exposure < __UNIFORM_DRAG_FLOAT1
      ui_label = "Exposure";
    > = 0.0;

    uniform float pivot < __UNIFORM_SLIDER_FLOAT1
      ui_label = "Contrast pivot";
      ui_min = 0.0;
      ui_max = 1.0;
    > = 0.435;

    uniform float contrast < __UNIFORM_DRAG_FLOAT1
      ui_label = "Contrast";
      ui_min = 0.0;
    > = 1.0;

    uniform float saturation < __UNIFORM_DRAG_FLOAT1
      ui_label = "Saturation";
      ui_min = 0.0;
    > = 1.0;

    UI_MESSAGE(help, __preprocessor_help_text__);
  }

  float3 ACEScct_to_linear(float3 _in)
  {
    return (_in > 0.155251141552511) ? exp2(_in * 17.52 - 9.72) : (_in - 0.0729055341958355) / 10.5402377416545;
  }

  float3 linear_to_ACEScct(float3 _in)
  {
    return (_in <= 0.0078125) ? 10.5402377416545 * _in + 0.0729055341958355 : (log2(_in) + 9.72) / 17.52;
  }

  float4 tex3Dhoriz(sampler2D s, float3 t, int3 texture_size, int atlas_index)
  {
    t = saturate(t);
    t = t * texture_size - t;

    float3 texel_size = rcp(texture_size);
    t.xy = (t.xy + 0.5) * texel_size.xy;
    
    float lerpfact = frac(t.z);
    t.x = (t.x + t.z - lerpfact) * texel_size.z;

    float2x2 uv = float2x2(t.xy, t.xy + float2(rcp(texture_size.z), 0.0));
    int2 atlas_size = tex2Dsize(s);
    int atlas_count = atlas_size.y * texel_size.y;

    uv[0].y = (uv[0].y + atlas_index) / atlas_count;
    uv[1].y = (uv[1].y + atlas_index) / atlas_count;
  
    return lerp(tex2Dlod(s, uv[0], 0), tex2Dlod(s, uv[1], 0), lerpfact);
  }

  float3 inverse_tonemap(float3 color)
  {
    float3 acescct = tex3D(lut, color.rgb, 32, 0).rgb;
    return ACEScct_to_linear(acescct);
  }

  float3 tonemap(float3 acescg)
  {
    float3 acescct = linear_to_ACEScct(acescg);
    return tex3D(lut, acescct.rgb, 32, 1).rgb;
  }

  float3 ps_main(vs_t vs): sv_target
  {
    float3 color = tex2D(backbuffer, vs.texcoord.xy).rgb;
    float3 acescg = inverse_tonemap(color);
    acescg *= exp2(ui::exposure);

    float3 acescct = linear_to_ACEScct(acescg);
    acescct = lerp(ui::pivot.rrr, acescct, ui::contrast.rrr);

    acescct = lerp(dot(acescct, float3(0.272229, 0.674082, 0.0536895)), acescct, ui::saturation);

    acescg = ACEScct_to_linear(acescct);

    color = tonemap(acescg);

    return color;
  }

  technique loathe_acesfixer <ui_label = "loathe::acesfixer";>
  {
    pass
    {
      PixelShader = ps_main;
      VertexShader = vs_quad;
    }
  }
}