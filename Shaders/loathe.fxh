// SPDX-License-Identifier: CC-BY-NC-SA-4.0+

#pragma once
#include "ReShade.fxh"
#include "ReShadeUI.fxh"

#define NULL (0)
#define TINY (1e-8)

#define where(_c, _x, _y) ((_c) ? (_x) : (_y))
#define linearstep(_min, _max, _x) (saturate(((_x) - (_min)) / ((_max) - (_min))))
#define cbrt(_x) (sign(_x) * pow(abs(_x), rcp(3.0)))

#define exp10(_x) (exp2((_x)*3.321928095))

namespace loathe {
  namespace std {
    texture2D backbuffer_texture : color;
    texture2D depthbuffer_texture : depth;

    sampler2D backbuffer { Texture = backbuffer_texture; };
    sampler2D depthbuffer { Texture = depthbuffer_texture; };

    sampler2D linear_backbuffer {
      Texture = backbuffer_texture;
      SRGBTexture = true;
    };

    struct vs_t {
      float4 position : sv_position;
      float2 texcoord : texcoord;
    };

    vs_t vs_quad(uint id
                 : sv_vertexid) {
      vs_t vs;

      vs.texcoord.x = id == 2 ? 2.0 : 0.0;
      vs.texcoord.y = id == 1 ? 2.0 : 0.0;
      vs.position = float4(vs.texcoord * float2(+2, -2) + float2(-1, +1), 0, 1);

      return vs;
    }

    float3x3 inverse(const float3x3 m) {
      float3x3 adjugate;
      adjugate[0][0] = (m[1][1] * m[2][2] - m[1][2] * m[2][1]);
      adjugate[0][1] = -(m[0][1] * m[2][2] - m[0][2] * m[2][1]);
      adjugate[0][2] = (m[0][1] * m[1][2] - m[0][2] * m[1][1]);
      adjugate[1][0] = -(m[1][0] * m[2][2] - m[1][2] * m[2][0]);
      adjugate[1][1] = (m[0][0] * m[2][2] - m[0][2] * m[2][0]);
      adjugate[1][2] = -(m[0][0] * m[1][2] - m[0][2] * m[1][0]);
      adjugate[2][0] = (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
      adjugate[2][1] = -(m[0][0] * m[2][1] - m[0][1] * m[2][0]);
      adjugate[2][2] = (m[0][0] * m[1][1] - m[0][1] * m[1][0]);

      float determinant = dot(float3(adjugate[0][0], adjugate[0][1], adjugate[0][2]), float3(m[0][0], m[1][0], m[2][0]));
      return adjugate * rcp(determinant + (abs(determinant) < TINY));
    }

    float3x3 diag(const float3 V) {
      float3x3 M = float3x3(V.x, 0.0, 0.0,
                            0.0, V.y, 0.0,
                            0.0, 0.0, V.z);

      return M;
    }
  } // namespace std
} // namespace loathe
