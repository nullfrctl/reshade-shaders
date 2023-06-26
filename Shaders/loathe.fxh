// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once
#include "ReShade.fxh"
#include "ReShadeUI.fxh"

#define NULL (0)
#define TINY (1e-8)

#define NL " \n "

// format for most things (headers, tooltips, text, etc.)
#define FORMAT(_str) NL _str NL

// spacing control; use in ui_spacing = width
#define THIN 1
#define REGULAR 3
#define WIDE 5

namespace std {
  float where(bool cond, float x, float y) { return cond ? x : y; }
  float2 where(bool2 cond, float2 x, float2 y) { return cond ? x : y; }
  float3 where(bool3 cond, float3 x, float3 y) { return cond ? x : y; }
  float4 where(bool4 cond, float4 x, float4 y) { return cond ? x : y; }

  texture2D backbuffer_texture : color;
  texture2D depthbuffer_texture : depth;

  sampler2D backbuffer { Texture = backbuffer_texture; };
  sampler2D depthbuffer { Texture = depthbuffer_texture; };

  sampler2D linear_backbuffer {
    Texture = backbuffer_texture;
    SRGBTexture = true;
  };

  struct VS_t {
    float4 position : SV_position;
    float2 texcoord : texcoord;
  };

  VS_t VS_quad(uint id
               : SV_vertexid) {
    VS_t VS;

    VS.texcoord.x = id == 2 ? 2.0 : 0.0;
    VS.texcoord.y = id == 1 ? 2.0 : 0.0;
    VS.position = float4(VS.texcoord * float2(+2, -2) + float2(-1, +1), 0, 1);

    return VS;
  }

  float3x3 inverse(const float3x3 M) {
    float3x3 adj;
    adj[0][0] = (M[1][1] * M[2][2] - M[1][2] * M[2][1]);
    adj[0][1] = -(M[0][1] * M[2][2] - M[0][2] * M[2][1]);
    adj[0][2] = (M[0][1] * M[1][2] - M[0][2] * M[1][1]);
    adj[1][0] = -(M[1][0] * M[2][2] - M[1][2] * M[2][0]);
    adj[1][1] = (M[0][0] * M[2][2] - M[0][2] * M[2][0]);
    adj[1][2] = -(M[0][0] * M[1][2] - M[0][2] * M[1][0]);
    adj[2][0] = (M[1][0] * M[2][1] - M[1][1] * M[2][0]);
    adj[2][1] = -(M[0][0] * M[2][1] - M[0][1] * M[2][0]);
    adj[2][2] = (M[0][0] * M[1][1] - M[0][1] * M[1][0]);

    float determinant = dot(float3(adj[0][0], adj[0][1], adj[0][2]), float3(M[0][0], M[1][0], M[2][0]));
    return adj * rcp(determinant + (abs(determinant) < TINY));
  }

  float2x2 diag(const float2 V) {
    return float2x2(V.x, 0.0,
                    0.0, V.y);
  }

  /*
  float2x3 diag(const float2 V) {
    return float2x3(V.x, 0.0, 0.0,
                    0.0, V.y, 0.0);
  }

  float3x2 diag(const float2 V) {
    return float3x2(V.x, 0.0,
                    0.0, V.y,
                    0.0, 0.0);
  }
  */

  float3x3 diag(const float3 V) {
    return float3x3(V.x, 0.0, 0.0,
                    0.0, V.y, 0.0,
                    0.0, 0.0, V.z);
  }

  /*
  float3x4 diag(const float3 V) {
    return float3x4(V.x, 0.0, 0.0, 0.0,
                    0.0, V.y, 0.0, 0.0,
                    0.0, 0.0, V.z, 0.0);
  }

  float4x3 diag(const float3 V) {
    return float4x3(V.x, 0.0, 0.0,
                    0.0, V.y, 0.0,
                    0.0, 0.0, V.z,
                    0.0, 0.0, 0.0);
  }
  */

  float4x4 diag(const float4 V) {
    return float4x4(V.x, 0.0, 0.0, 0.0,
                    0.0, V.y, 0.0, 0.0,
                    0.0, 0.0, V.z, 0.0,
                    0.0, 0.0, 0.0, V.w);
  }
} // namespace std
