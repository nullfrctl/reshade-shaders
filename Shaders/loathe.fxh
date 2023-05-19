// SPDX-License-Identifier: CC-BY-NC-SA-4.0+

#pragma once
#include "ReShade.fxh"
#include "ReShadeUI.fxh"

#define _m(_a,_b) _a##_b
#define _s(_a) #_a
#define _n "\n"

#define NULL 0
#define TINY 1e-8

#define sum(_v)  (dot((_v),1.0))
#define linearstep(_min,_max,_x) (saturate(((_x) - (_min)) * rcp((_max) - (_min))))
#define where(_cond,_a,_b) ((_cond)?(_a):(_b))

#define UI_MESSAGE(_name, _text) uniform int _m(message, _name) < __UNIFORM_RADIO_INT1 ui_label = " "; ui_text = _n _text; > = NULL

namespace loathe
{
  texture2D backbuffer_texture: color;
  texture2D depthbuffer_texture: depth;

  sampler2D backbuffer
  {
    Texture = backbuffer_texture;
  };

  sampler2D depthbuffer
  {
    Texture = depthbuffer_texture;
  };

  float4 tex2Dlod(sampler2D s, float2 t, float m)
  {
    return tex2Dlod(s, float4(t, 0, m));
  }

  struct vs_t
  {
    float4 position: sv_position;
    float2 texcoord: texcoord;
  };

  vs_t vs_quad(uint id: sv_vertexid)
  {
    vs_t vs;

    vs.texcoord.x = (id == 2) ? 2.0 : 0.0;
    vs.texcoord.y = (id == 1) ? 2.0 : 0.0;
    vs.position = float4(vs.texcoord * float2(+2, -2) + float2(-1, +1), 0, 1);

    return vs;
  }
} // namespace loathe
