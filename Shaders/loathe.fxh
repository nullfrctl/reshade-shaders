// SPDX-License-Identifier: CC-BY-NC-SA-4.0+

#pragma once
#include "ReShade.fxh"
#include "ReShadeUI.fxh"

#define _m(a,b) a##b
#define _s(a) #a
#define NULL (0) // winapi style null.

#define _n "\n"
#define __preprocessor_help_text__ \
"Display gamma can be ITU or IEC specification name (e.g. sRGB, Rec709)" _n \
"or number (e.g. 61966, 709)." _n \
_n \
"You can also input a custom gamma through a 2-digit " _n \
"number (e.g. 24 for 2.4, 10 for 1.0/linear)" _n \
_n \
"Currently only sRGB (61966) and Rec709 (709) are implemented" _n \
"If you use a TV, input 'Rec709'. If you use a monitor, input 'sRGB'."

#define UI_MESSAGE(_name, _text) uniform int _m(message, _name) < __UNIFORM_RADIO_INT1 ui_label = " "; ui_text = "\n" _text; > = NULL

// gamma for display.
#define sRGB 61966 // IEC 61966-2-1:1999
#define Rec709 709 // ITU-R BT.709

#ifndef DISPLAY_GAMMA
  #define DISPLAY_GAMMA sRGB // can also be Rec709
#endif

namespace loathe
{

namespace _sRGB
{

/*
Copyright 2013 Colour Developers
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Colour Developers nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL COLOUR DEVELOPERS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

float3 inverse_EOTF(float3 y)
{
  y = abs(y);
  float3 x = y <= 0.0031308 ? y * 12.9232102 : 1.055 * pow(y, rcp(2.4)) - 0.055;
  return x;
}

float3 EOTF(float3 x)
{
  x = abs(x);
  float3 y = inverse_EOTF(0.0031308) >= x ? x / 12.9232102 : pow((x + 0.055) / 1.055, 2.4);
  return y;
}

}

namespace _Rec709
{

float3 OETF(float3 L)
{
  L = abs(L);
  float3 V = L < 0.018053968510807 ? 4.5 * L : 1.099296826809442 * pow(L, rcp(2.2)) - 0.099296826809442;

  return V;
}

float3 inverse_OETF(float3 V)
{
  V = abs(V);
  float3 L = V < 0.018053968510807 ? V / 4.5 : pow((V + 0.099296826809442) / 1.099296826809442, 2.2);

  return L;
}

}

#if (DISPLAY_GAMMA == sRGB)
  #define signal_to_linear(x) (::loathe::_sRGB::EOTF(x))
  #define linear_to_signal(x) (::loathe::_sRGB::inverse_EOTF(x))
#elif (DISPLAY_GAMMA == Rec709)
  #define signal_to_linear(x) (::loathe::_Rec709::inverse_OETF(x))
  #define linear_to_signal(x) (::loathe::_Rec709::OETF(x))
#else
  #define signal_to_linear(x) (pow(x, DISPLAY_GAMMA * 0.1))
  #define linear_to_signal(x) (pow(x, rcp(DISPLAY_GAMMA * 0.1)))
#endif

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

float get_depth(in vs_t vs, in float far_plane)
{
  // vflip depth.
  #if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
  vs.texcoord.y = 1.0 - vs.texcoord.y;
  #endif

  // scale depth.
  #if (RESHADE_DEPTH_INPUT_X_SCALE && RESHADE_DEPTH_INPUT_Y_SCALE)
  vs.texcoord.xy /= float2(RESHADE_DEPTH_INPUT_X_SCALE, RESHADE_DEPTH_INPUT_Y_SCALE);
  #endif

  // pixel offsets.
  #if (RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET)
  vs.texcoord.x -= RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET * BUFFER_RCP_WIDTH;
  #else
  vs.texcoord.x -= RESHADE_DEPTH_INPUT_X_OFFSET * 0.5;
  #endif

  #if (RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET)
  vs.texcoord.x -= RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET * BUFFER_RCP_HEIGHT;
  #else
  vs.texcoord.x -= RESHADE_DEPTH_INPUT_Y_OFFSET * 0.5;
  #endif

  float depth = tex2Dlod(depthbuffer, float4(vs.texcoord.xy, 0, 0)).x;
  
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

float get_depth(in vs_t vs)
{
  return get_depth(vs, RESHADE_DEPTH_LINEARIZATION_FAR_PLANE);
}

}
