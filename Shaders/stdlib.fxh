#pragma once

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

#define ADDRESS(_address) \
AddressU = _address;      \
AddressV = _address;      \
AddressW = _address

#define FILTER(_filter) \
MagFilter = _filter;    \
MinFilter = _filter;    \
MipFilter = _filter

#define DIMENSIONS(_width, _height) \
Width = _width;                     \
Height = _height

#define NULL 0

#define where(_condition, _x, _y) ((_condition) ? (_x) : (_y))
#define expand(_min, _max, _x) (((_x) - (_min)) / ((_max) - (_min)))
#define linearstep(_min, _max, _x) (saturate(expand(_min, _max, _x)))

#define cexp2(_x) (1 << (_x))

namespace std 
{
  float aspect_ratio() { return BUFFER_WIDTH * BUFFER_RCP_HEIGHT; }
  float2 pixel_size() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
  float2 screen_size() { return float2(BUFFER_WIDTH, BUFFER_HEIGHT); }

  uint bit_depth() { return BUFFER_COLOR_BIT_DEPTH; }
  uint color_space() { return BUFFER_COLOR_SPACE; }

  struct VS_t 
  {
    float4 position : SV_POSITION;
    float2 texcoord : TEXCOORD;
  };

  texture2D back_buffer_texture : COLOR;
  texture2D depth_buffer_texture : DEPTH;

  sampler2D back_buffer { Texture = back_buffer_texture; };
  sampler2D depth_buffer { Texture = depth_buffer_texture; };

  VS_t VS_quad(uint id : SV_VERTEXID) 
  {
    VS_t VS;

    VS.texcoord.x = id == 2 ? 2.0 : 0.0;
    VS.texcoord.y = id == 1 ? 2.0 : 0.0;

    VS.position = float4(VS.texcoord * float2(+2, -2) + float2(-1, +1), 0, 1);

    return VS;
  }
} // namespace std