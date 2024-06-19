#pragma once

namespace Dual
{
  // `n' refers to the divisor or half of the original buffer this is.
  // n=1 is one half the original res, n=2 is a quarter, and so on.

  float3 downsample(in sampler2D T, in float2 texcoord, in uint n, in float2 offset)
  {
    const float2 px = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * (1 << n) * offset;
    const float2 hpx = (px/2);

    float3 sum = tex2D(T, texcoord.xy).rgb * 4;
    sum += tex2D(T, texcoord.xy - hpx.xy).rgb;
    sum += tex2D(T, texcoord.xy + hpx.xy).rgb;
    sum += tex2D(T, texcoord.xy + float2(hpx.x,-hpx.y)).rgb;
    sum += tex2D(T, texcoord.xy - float2(hpx.x,-hpx.y)).rgb;

    return sum / 8;
  }
  
  float3 downsample(in sampler2D T, in float2 texcoord, in uint n)
  {
    return downsample(T,texcoord,n,1);
  }

  float3 upsample(in sampler2D T, in float2 texcoord, in uint n, in float2 offset)
  {
    const float2 px = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * (1 << n) * offset;
    const float2 hpx = (px/2);

    float3 sum = tex2D(T, texcoord + float2(-px.x,0)).rgb;
    sum += tex2D(T, texcoord + float2(-hpx.x, hpx.y)).rgb * 2;
    sum += tex2D(T, texcoord + float2(0, px.y)).rgb;
    sum += tex2D(T, texcoord + hpx).rgb * 2;
    sum += tex2D(T, texcoord + float2(px.x, 0)).rgb;
    sum += tex2D(T, texcoord + float2(hpx.x, -hpx.y)).rgb * 2;
    sum += tex2D(T, texcoord + float2(0, -px.y)).rgb;
    sum += tex2D(T, texcoord - hpx).rgb * 2;

    return sum / 12;
  }
  
  float3 upsample(in sampler2D T, in float2 texcoord, in uint n)
  {
    return upsample(T,texcoord,n,1);
  }
}

float4 fetch(in sampler2D T, in float4 p)
{
  return tex2Dfetch(T, uint2(p.xy));
}