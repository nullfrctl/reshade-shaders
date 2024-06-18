/*

  [  a n a g r a m a  ]

                         */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "sampling.fxh"

uniform float Blend < __UNIFORM_SLIDER_FLOAT1
  ui_min = 0;
  ui_max = 1;
  ui_label = " Blend.";
  ui_tooltip = "Blends between the hyperblur and the original image. Can be used for bloom.";
  ui_spacing = 4;
> = 1.0;

uniform float2 Offset < __UNIFORM_DRAG_FLOAT2
  ui_min = 1;
  ui_label = " Offset.";
  ui_tooltip = "Changes the size of a 'pixel' in the blur calculation. Bigger values result in wider blur.";
  ui_spacing = 4;
> = 1;


/* § Textures and Samplers. */

sampler2D back_buffer
{
  Texture = ReShade::BackBufferTex;
  SRGBTexture = true;
};

// We can re-use textures due to the linear and descending order of hyperblur.

namespace T
{
  texture2D Z
  {
    Width  = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
  };

  texture2D I
  {
    Width  = BUFFER_WIDTH  / 2;
    Height = BUFFER_HEIGHT / 2;
    Format = RGBA16F;
  };

  texture2D II
  {
    Width  = BUFFER_WIDTH  / 4;
    Height = BUFFER_HEIGHT / 4;
    Format = RGBA16F;
  };

  texture2D III
  {
    Width  = BUFFER_WIDTH  / 8;
    Height = BUFFER_HEIGHT / 8;
    Format = RGBA16F;
  };

  texture2D IV
  {
    Width  = BUFFER_WIDTH  / 16;
    Height = BUFFER_HEIGHT / 16;
    Format = RGBA16F;
  };

  texture2D V
  {
    Width  = BUFFER_WIDTH  / 32;
    Height = BUFFER_HEIGHT / 32;
    Format = RGBA16F;
  };

  texture2D VI
  {
    Width  = BUFFER_WIDTH  / 64;
    Height = BUFFER_HEIGHT / 64;
    Format = RGBA16F;
  };
}

sampler2D Z   { Texture = T::Z;   };
sampler2D I   { Texture = T::I;   };
sampler2D II  { Texture = T::II;  };
sampler2D III { Texture = T::III; };
sampler2D IV  { Texture = T::IV;  };
sampler2D V   { Texture = T::V;   };
sampler2D VI  { Texture = T::VI;  };

// Z fetch.
float3 Zf(float4 p)
{
  return tex2Dfetch(Z, uint2(p.xy)).rgb;
}

namespace u1
{
  float3 I(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return Zf(_) + ::Dual::upsample(::I, t, 1, Offset);
  }
}


namespace u2
{
  float3 I(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::II, t, 2, Offset);
  }

  float3 II(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return Zf(_) + ::Dual::upsample(::I, t, 1, Offset);
  }
}

namespace u3
{
  float3 I(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::III, t, 3, Offset);
  }

  float3 II(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::II, t, 2, Offset);
  }

  float3 III(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return Zf(_) + ::Dual::upsample(::I, t, 1, Offset);
  }
}


namespace u4
{
  float3 I(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::IV, t, 4, Offset);
  }

  float3 II(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::III, t, 3, Offset);
  }

  float3 III(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::II, t, 2, Offset);
  }

  float3 IV(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return Zf(_) + ::Dual::upsample(::I, t, 1, Offset);
  }
}


namespace u5
{
  float3 I(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::V, t, 5, Offset);
  }

  float3 II(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::IV, t, 4, Offset);
  }

  float3 III(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::III, t, 3, Offset);
  }

  float3 IV(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::II, t, 2, Offset);
  }

  float3 V(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return Zf(_) + ::Dual::upsample(::I, t, 1, Offset);
  }
}

namespace u6
{
  float3 I(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::VI, t, 6, Offset);
  }

  float3 II(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::V, t, 5, Offset);
  }

  float3 III(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::IV, t, 4, Offset);
  }

  float3 IV(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::III, t, 3, Offset);
  }

  float3 V(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::upsample(::II, t, 2, Offset);
  }

  float3 VI(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return Zf(_) + ::Dual::upsample(::I, t, 1, Offset);
  }
}


namespace d
{
  void I
  (
    in  float4 _ : SV_Position, 
    in  float2 t : TEXCOORD,
    out float3 I : SV_Target
  )
  {
    I = ::Dual::downsample(::Z, t, 1);
  }

  void II
  (
    in  float4 _  : SV_Position, 
    in  float2 t  : TEXCOORD,
    out float3 II : SV_Target
  )
  {
    II = ::Dual::downsample(::I, t, 2);
  }

  void III
  (
    in  float4 _   : SV_Position, 
    in  float2 t   : TEXCOORD,
    out float3 III : SV_Target
  )
  {
    III = ::Dual::downsample(::II, t, 3);
  }

  void IV
  (
    in  float4 _  : SV_Position, 
    in  float2 t  : TEXCOORD,
    out float3 IV : SV_Target
  )
  {
    IV = ::Dual::downsample(::III, t, 4);
  }

  void V
  (
    in  float4 _ : SV_Position, 
    in  float2 t : TEXCOORD,
    out float3 V : SV_Target
  )
  {
    V = ::Dual::downsample(::IV, t, 5);
  }

  void VI
  (
    in  float4 _  : SV_Position, 
    in  float2 t  : TEXCOORD,
    out float3 VI : SV_Target
  )
  {
    VI = ::Dual::downsample(::V, t, 6);
  }
}

float3 tone_map(float3 c) { return c / (1+c); }
float3 inverse_tone_map(float3 c) { return -(c / (c-1.01)); }

void InverseToneMapPS
(
  in float4 position : SV_Position,
  in float2 texcoord : TEXCOORD,
  out float4 hdr     : SV_Target0
)
{
  hdr = float4(inverse_tone_map(tex2Dfetch(back_buffer, uint2(position.xy)).rgb), 1);
}

float3 HyperblendPS(in float4 position : SV_Position, in float2 texcoord : TEXCOORD) : SV_Target
{
  uint2 p = uint2(position.xy);

  float3 hdr  = inverse_tone_map(tex2Dfetch(back_buffer, p).rgb);
  float3 blur = Zf(position) / 6;

  float3 color = lerp(hdr, blur, Blend);

  return tone_map(color);
}

technique Hyperblur
<
  ui_label = "anagrama hyperblur.";
  ui_tooltip = "A special and perfectionist blur shader specialized for bloom. \n"
               "Part of the Anagrama shader collection [nullfrctl/reshade-shaders].";
>
{
  /* Initialization. */

  pass
  {
    VertexShader = PostProcessVS;
    PixelShader  = InverseToneMapPS;
    RenderTarget = T::Z;
    ClearRenderTargets = true;
  }

  /* Downsampling. */

  pass d1
  {
    VertexShader = PostProcessVS;
    PixelShader  = d::I;
    RenderTarget = T::I;
  }

  pass d2
  {
    VertexShader = PostProcessVS;
    PixelShader  = d::II;
    RenderTarget = T::II;
  }

  pass d3
  {
    VertexShader = PostProcessVS;
    PixelShader  = d::III;
    RenderTarget = T::III;
  }

  pass d4
  {
    VertexShader = PostProcessVS;
    PixelShader  = d::IV;
    RenderTarget = T::IV;
  }

  pass d5
  {
    VertexShader = PostProcessVS;
    PixelShader  = d::V;
    RenderTarget = T::V;
  }

  pass d6
  {
    VertexShader = PostProcessVS;
    PixelShader  = d::VI;
    RenderTarget = T::VI;
  }

  /* U-group one. */

  pass u1_I
  {
    VertexShader = PostProcessVS;
    PixelShader  = u1::I;
    RenderTarget = T::Z;
  }

  /* U-group two. */

  pass u2_I
  {
    VertexShader = PostProcessVS;
    PixelShader  = u2::I;
    RenderTarget = T::I;
  }

  pass u2_II
  {
    VertexShader = PostProcessVS;
    PixelShader  = u2::II;
    RenderTarget = T::Z;
  }

  /* U-group three. */

  pass u3_I
  {
    VertexShader = PostProcessVS;
    PixelShader  = u3::I;
    RenderTarget = T::II;
  }

  pass u3_II
  {
    VertexShader = PostProcessVS;
    PixelShader  = u3::II;
    RenderTarget = T::I;
  }

  pass u3_III
  {
    VertexShader = PostProcessVS;
    PixelShader  = u3::III;
    RenderTarget = T::Z;
  }

  /* U-group four. */

  pass u4_I
  {
    VertexShader = PostProcessVS;
    PixelShader  = u4::I;
    RenderTarget = T::III;
  }

  pass u4_II
  {
    VertexShader = PostProcessVS;
    PixelShader  = u4::II;
    RenderTarget = T::II;
  }

  pass u4_III
  {
    VertexShader = PostProcessVS;
    PixelShader  = u4::III;
    RenderTarget = T::I;
  }

  pass u4_IV
  {
    VertexShader = PostProcessVS;
    PixelShader  = u4::IV;
    RenderTarget = T::Z;
  }

  /* U-group five. */

  pass u5_I
  {
    VertexShader = PostProcessVS;
    PixelShader  = u5::I;
    RenderTarget = T::IV;
  }

  pass u5_II
  {
    VertexShader = PostProcessVS;
    PixelShader  = u5::II;
    RenderTarget = T::III;
  }

  pass u5_III
  {
    VertexShader = PostProcessVS;
    PixelShader  = u5::III;
    RenderTarget = T::II;
  }

  pass u5_IV
  {
    VertexShader = PostProcessVS;
    PixelShader  = u5::IV;
    RenderTarget = T::I;
  }

  pass u5_V
  {
    VertexShader = PostProcessVS;
    PixelShader  = u5::V;
    RenderTarget = T::Z;
  }

  /* U-group six. */

  pass u6_I
  {
    VertexShader = PostProcessVS;
    PixelShader  = u6::I;
    RenderTarget = T::V;
  }

  pass u6_II
  {
    VertexShader = PostProcessVS;
    PixelShader  = u6::II;
    RenderTarget = T::IV;
  }

  pass u6_III
  {
    VertexShader = PostProcessVS;
    PixelShader  = u6::III;
    RenderTarget = T::III;
  }

  pass u6_IV
  {
    VertexShader = PostProcessVS;
    PixelShader  = u6::IV;
    RenderTarget = T::II;
  }

  pass u6_V
  {
    VertexShader = PostProcessVS;
    PixelShader  = u6::V;
    RenderTarget = T::I;
  }

  pass u6_VI
  {
    VertexShader = PostProcessVS;
    PixelShader  = u6::VI;
    RenderTarget = T::Z;
  }

  /* Finalization. */

  pass
  {
    VertexShader = PostProcessVS;
    PixelShader  = HyperblendPS;
    SRGBWriteEnable = true;
  }
}