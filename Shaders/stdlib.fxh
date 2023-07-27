#pragma once

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

#define _ADDRESS(_address)                                                                         \
	AddressU = _address;                                                                             \
	AddressV = _address;                                                                             \
	AddressW = _address

#define _FILTER(_filter)                                                                           \
	MagFilter = _filter;                                                                             \
	MinFilter = _filter;                                                                             \
	MipFilter = _filter

#define _DIMENSIONS(_width, _height)                                                               \
	Width = _width;                                                                                  \
	Height = _height

// C-style NULL
#define NULL 0

#define where(_condition, _x, _y) ((_condition) ? (_x) : (_y))
#define linearstep(_min, _max, _x) (saturate(((_x) - (_min)) * rcp((_max) - (_min))))

namespace std {
	float aspect_ratio() { return BUFFER_WIDTH * BUFFER_RCP_HEIGHT; }
	float2 pixel_size() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
	float2 screen_size() { return float2(BUFFER_WIDTH, BUFFER_HEIGHT); }

	uint bit_depth() { return BUFFER_COLOR_BIT_DEPTH; }
	uint color_space() { return BUFFER_COLOR_SPACE; }

	// #include "_where.fxh"

	struct VS_t {
		float4 position : SV_position;
		float2 texcoord : texcoord;
	};

	texture2D back_buffer_texture : color;
	texture2D depth_buffer_texture : depth;

	sampler2D back_buffer { Texture = back_buffer_texture; };
	sampler2D depth_buffer { Texture = depth_buffer_texture; };

	VS_t VS_quad(uint id : SV_vertexID) {
		VS_t VS;

		VS.texcoord.x = id == 2 ? 2.0 : 0.0;
		VS.texcoord.y = id == 1 ? 2.0 : 0.0;

		VS.position = float4(VS.texcoord * float2(+2, -2) + float2(-1, +1), 0, 1);

		return VS;
	}
} // namespace std