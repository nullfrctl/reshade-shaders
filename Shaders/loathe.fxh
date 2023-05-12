// SPDX-License-Identifier: CC-BY-NC-SA-4.0+

#pragma once
#include "ReShade.fxh"
#include "ReShadeUI.fxh"

#define _m(a,b) a##b
#define _s(a) #a
#define NULL (0)

#define _n "\n"
#define UI_MESSAGE(_name, _text) uniform int _m(message, _name) < __UNIFORM_RADIO_INT1 ui_label = " "; ui_text = "\n" _text; > = NULL

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

struct vs_t
{
  float4 position: sv_position;
  float2 texcoord: texcoord;
};

vs_t vs_quad(in uint id: sv_vertexid)
{
  vs_t vs;

  vs.texcoord.x = (id == 2) ? 2.0 : 0.0;
  vs.texcoord.y = (id == 1) ? 2.0 : 0.0;
  vs.position = float4(vs.texcoord * float2(+2, -2) + float2(-1, +1), 0, 1);

  return vs;
}

float get_depth(in float2 texcoord, in float far_plane)
{
  // vflip depth.
  #if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
  texcoord.y = 1.0 - texcoord.y;
  #endif

  // scale depth.
  #if (RESHADE_DEPTH_INPUT_X_SCALE && RESHADE_DEPTH_INPUT_Y_SCALE)
  texcoord.xy /= float2(RESHADE_DEPTH_INPUT_X_SCALE, RESHADE_DEPTH_INPUT_Y_SCALE);
  #endif

  // pixel offsets.
  #if (RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET)
  texcoord.x -= RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET * BUFFER_RCP_WIDTH;
  #else
  texcoord.x -= RESHADE_DEPTH_INPUT_X_OFFSET * 0.5;
  #endif

  #if (RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET)
  texcoord.x -= RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET * BUFFER_RCP_HEIGHT;
  #else
  texcoord.x -= RESHADE_DEPTH_INPUT_Y_OFFSET * 0.5;
  #endif

  float depth = tex2Dlod(depthbuffer, float4(texcoord.xy, 0, 0)).x;
  
  // multiplier
  #if (RESHADE_DEPTH_MULTIPLIER)
	depth *= RESHADE_DEPTH_MULTIPLIER;
	#endif

  // logarithmic depth.
  #if (RESHADE_DEPTH_INPUT_IS_LOGARITHMIC)
  depth = (exp(depth * log(0.01 + 1.0)) - 1.0) * 100.0;
  #endif

  // reverse depth.
  #if (RESHADE_DEPTH_INPUT_IS_REVERSED)
  depth = 1.0 - depth;
  #endif

  depth /= far_plane - depth * (far_plane - 1.0);

  return depth;
}

float get_depth(in float2 texcoord)
{
  return get_depth(texcoord, RESHADE_DEPTH_LINEARIZATION_FAR_PLANE);
}

}
