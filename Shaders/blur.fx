/*

  [  a n a g r a m a  ]

                         */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "sampling.fxh"

/* § User Interface. */

uniform float Blend < __UNIFORM_SLIDER_FLOAT1
  ui_min = 0;
  ui_max = 1;
  ui_label = " Blend.";
  ui_tooltip = "Blends between the blur and the original image. Can be used for lens diffusion.";
  ui_spacing = 4;
> = 0.5;

uniform float W < __UNIFORM_DRAG_FLOAT1
  ui_min = 1;
  ui_max = 3;
  ui_label = " Log HDR whitepoint.";
  ui_tooltip = "The largest attainable HDR value in 10^n scale.";
> = 2;

uniform float2 Offset < __UNIFORM_DRAG_FLOAT2
  ui_min = 1;
  ui_label = " Offset.";
  ui_tooltip = "Changes the size of a 'pixel' in the blur calculation. Bigger values result in wider blur.";
  ui_spacing = 4;
> = 1;

uniform bool Aphysical < __UNIFORM_COMBO_BOOL1
  ui_label = " Aphysical blend.";
  ui_spacing = 4;
  ui_tooltip = "Blends the blur in a way closer to how games often (wrongly) blend bloom: additively.\n"
               "This mode is not additive, but likewise allows for thresholds [see below].";
> = false;

uniform float Threshold < __UNIFORM_DRAG_FLOAT1
  ui_min = 0;
  ui_label = " Aphysical threshold.";
  ui_tooltip = "An amount of light which must be reached for the blur to recognize it. Not physically correct.";
> = 10;

uniform bool Dither <
  ui_label = " Debanding.";
  ui_spacing = 4;
> = true;

/* § Textures and Samplers. */

sampler2D back_buffer
{
  Texture = ReShade::BackBufferTex;
  SRGBTexture = true;
};

// We can re-use textures due to the linear nature of dual filter blur.

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

  texture2D blue_noise
  <
    source = "blue_noise.dds";
  >
  {
    Width = 512;
    Height = 512;
    Format = R8;
  };
}

#define MIRROR AddressU = MIRROR; AddressV = MIRROR

sampler2D Z   { Texture = T::Z;   MIRROR; };
sampler2D I   { Texture = T::I;   MIRROR; };
sampler2D II  { Texture = T::II;  MIRROR; };
sampler2D III { Texture = T::III; MIRROR; };
sampler2D IV  { Texture = T::IV;  MIRROR; };
sampler2D V   { Texture = T::V;   MIRROR; };
sampler2D VI  { Texture = T::VI;  MIRROR; };

sampler2D blue_noise  
{
  Texture = T::blue_noise;
  AddressU = REPEAT;
  AddressV = REPEAT;
};

/* § Functions. */

// Z fetch.
float3 Zf(float4 p)
{
  return fetch(Z,p).rgb;
}

float3 tone_map(float3 c) { return c / (1+c); }
float3 inverse_tone_map(float3 c) { return -(c / (c-(1+pow(10,-W)))); }

/* § Shaders. */

namespace d
{
  float3 I(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::downsample(::Z, t, 1, Offset);
  }

  float3 II(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::downsample(::I, t, 2, Offset);
  }

  float3 III(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::downsample(::II, t, 3, Offset);
  }

  float3 IV(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::downsample(::III, t, 4, Offset);
  }

  float3 V(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::downsample(::IV, t, 5, Offset);
  }

  float3 VI(float4 _ : SV_Position, float2 t : TEXCOORD) : SV_Target
  {
    return ::Dual::downsample(::V, t, 6, Offset);
  }
}

namespace u
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
    return ::Dual::upsample(::I, t, 1, Offset);
  }
}

float3 InverseToneMapPS(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
  float3 c = inverse_tone_map(fetch(back_buffer, position).rgb);

  if (Aphysical)
  {  
    float br = max(c.r,max(c.g,c.b));
    c *= max(0, br - Threshold) / max(br, 1e-5);
  }
  
  return c;
}

float3 BlendPS(in float4 position : SV_Position, in float2 texcoord : TEXCOORD) : SV_Target
{
  if(Dither)
    position.xy += fetch(blue_noise, position).rr - 0.5;

  float3 hdr  = inverse_tone_map(fetch(back_buffer, position).rgb);
  float3 blur = Zf(position);

  float3 color;
  
  if (Aphysical)
    color = lerp(hdr, (hdr + (blur / (1 + blur))), Blend);
  else
    color = lerp(hdr, blur, Blend);
    
  return tone_map(color);
}

technique Blur
<
  ui_label = "blur (lens diffusion).";
  ui_tooltip = "A simple, quick blur shader apt at simulating lens diffusion. \n"
               "Part of the Anagrama shader collection [nullfrctl/reshade-shaders].\n"
               "\n"
               "(C) 2024 Santiago Velasquez. All Rights Reserved.";
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

  pass d_I
  {
    VertexShader = PostProcessVS;
    PixelShader  = d::I;
    RenderTarget = T::I;
  }

  pass d_II
  {
    VertexShader = PostProcessVS;
    PixelShader  = d::II;
    RenderTarget = T::II;
  }

  pass d_III
  {
    VertexShader = PostProcessVS;
    PixelShader  = d::III;
    RenderTarget = T::III;
  }

  pass d_IV
  {
    VertexShader = PostProcessVS;
    PixelShader  = d::IV;
    RenderTarget = T::IV;
  }

  pass d_V
  {
    VertexShader = PostProcessVS;
    PixelShader  = d::V;
    RenderTarget = T::V;
  }

  pass d_VI
  {
    VertexShader = PostProcessVS;
    PixelShader  = d::VI;
    RenderTarget = T::VI;
  }

  /* Upsample */

  pass u_I
  {
    VertexShader = PostProcessVS;
    PixelShader  = u::I;
    RenderTarget = T::V;
  }

  pass u_II
  {
    VertexShader = PostProcessVS;
    PixelShader  = u::II;
    RenderTarget = T::IV;
  }

  pass u_III
  {
    VertexShader = PostProcessVS;
    PixelShader  = u::III;
    RenderTarget = T::III;
  }

  pass u_IV
  {
    VertexShader = PostProcessVS;
    PixelShader  = u::IV;
    RenderTarget = T::II;
  }

  pass u_V
  {
    VertexShader = PostProcessVS;
    PixelShader  = u::V;
    RenderTarget = T::I;
  }

  pass u_VI
  {
    VertexShader = PostProcessVS;
    PixelShader  = u::VI;
    RenderTarget = T::Z;
  }

  /* Finalization. */

  pass
  {
    VertexShader = PostProcessVS;
    PixelShader  = BlendPS;
    SRGBWriteEnable = true;
  }
}