
#pragma once

uint where(bool condition, uint x, uint y) { return (condition ? x : y); }
uint2 where(bool2 condition, uint2 x, uint2 y) { return (condition ? x : y); }
uint3 where(bool3 condition, uint3 x, uint3 y) { return (condition ? x : y); }
uint4 where(bool4 condition, uint4 x, uint4 y) { return (condition ? x : y); }

int where(bool condition, int x, int y) { return (condition ? x : y); }
int2 where(bool2 condition, int2 x, int2 y) { return (condition ? x : y); }
int3 where(bool3 condition, int3 x, int3 y) { return (condition ? x : y); }
int4 where(bool4 condition, int4 x, int4 y) { return (condition ? x : y); }

float where(bool condition, float x, float y) { return (condition ? x : y); }
float2 where(bool2 condition, float x, float y) { return (condition ? x : y); }
float3 where(bool3 condition, float x, float y) { return (condition ? x : y); }
float4 where(bool4 condition, float x, float y) { return (condition ? x : y); }