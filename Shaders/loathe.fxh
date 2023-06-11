// SPDX-License-Identifier: CC-BY-NC-SA-4.0+

#pragma once
#include "ReShade.fxh"
#include "ReShadeUI.fxh"

#define NULL (0)
#define TINY (1e-8)

#define where(_c, _x, _y) ((_c) ? (_x) : (_y))
#define linearstep(_min, _max, _x) (saturate(((_x) - (_min)) / ((_max) - (_min))))

// precise-ish approx of pow(10,x)
#define exp10(_x) (exp2((_x)*3.321928095))
#define logn(_x, _n) (log2((_x)) / log2((_n)))

namespace loathe {
  texture2D backbuffer_texture : color;
  texture2D depthbuffer_texture : depth;

  sampler2D backbuffer { Texture = backbuffer_texture; };
  sampler2D depthbuffer { Texture = depthbuffer_texture; };

  struct vs_t {
    float4 position : sv_position;
    float2 texcoord : texcoord;
  };

  float max(float2 xy) {
    return max(xy.x, xy.y);
  }

  float max(float x, float y, float z) {
    return max(x, max(y, z));
  }

  float max(float3 xyz) {
    return max(xyz.x, max(xyz.y, xyz.z));
  }

  float max(float x, float y, float z, float w) {
    return max(x, max(y, max(z, w)));
  }

  float max(float4 xyzw) {
    return max(xyzw.x, max(xyzw.y, max(xyzw.z, xyzw.w)));
  }

  vs_t vs_quad(uint id
               : sv_vertexid) {
    vs_t vs;

    vs.texcoord.x = id == 2 ? 2.0 : 0.0;
    vs.texcoord.y = id == 1 ? 2.0 : 0.0;
    vs.position = float4(vs.texcoord * float2(+2, -2) + float2(-1, +1), 0, 1);

    return vs;
  }
} // namespace loathe
