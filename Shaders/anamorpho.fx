/*

  [  a n a g r a m a  ]

                         */

// This Program ("Anamorpho") contains Work by Jakub Maksymilian Fober,
// who has released it to the Public Domain.

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

/* § User Interface. */

uniform uint HELP < __UNIFORM_RADIO_INT1
  ui_spacing = 4;
  ui_label = " ";
  ui_category = " INSTRUCTIONS";
  ui_category_closed = true;
  ui_text = "i.  To use Anamorpho, you must place the Squeeze technique at the very top of the shaders you want to take on an anamorphic format. These should be shaders that manipulate color or add only post-processing effects and NOT depth-based ones like GI, AO, etc.\n"
            "\n"
            "ii. Then, after all of these have been put after the Squeeze technique, enable the Desqueeze technique. Once both are enabled, image should go back to normal and look as it should, only that the desired effects have been distorted in a way alike to how they'd behave under an anamorphic lens.\n"
            "\n"
            "    This process incurs a slight amount of blur (especially at higher squeeze factors), so running at a higher resolution is recommended for the best results.";
>;

uniform float SqueezeFactor < __UNIFORM_DRAG_FLOAT1
  ui_spacing = 4;
  ui_min = 1.333;
  ui_max = 2;
  ui_label = " Squeeze factor.";
> = BUFFER_ASPECT_RATIO;

uniform float2 FilmDimensions < __UNIFORM_DRAG_FLOAT2
  ui_min = float2(4,3);
  ui_label = " Film dimensions.";
  ui_units = "mm";
  ui_tooltip = "Allows you to select the simulated dimensions of the film used in the anamorphic process.\n"
               "Useful with crop enabled.";
  ui_spacing = 4;
> = float2(21.95,18.6);

uniform bool Letterbox < __UNIFORM_COMBO_BOOL1
  ui_label = " Crop.";
  ui_tooltip = "Adds a letterbox (or pillarbox) simulating the anamorphic aspect ratio of the selected film.";
> = false;

/* § Textures and Samplers. */

sampler2D back_buffer
{
  Texture = ReShade::BackBufferTex;
  AddressU = MIRROR;
  AddressV = BORDER;
  
  SRGBTexture = true;
};

bool border(float2 texcoord)
{
  const float film_aspect_ratio = SqueezeFactor*(FilmDimensions.x / FilmDimensions.y);
  const float aspect_ratio = BUFFER_ASPECT_RATIO;
    
  if (aspect_ratio == film_aspect_ratio || !Letterbox) 
    return true;
  else if (film_aspect_ratio > aspect_ratio) {
    // letterbox
    float b = 0.5 - aspect_ratio / (2*film_aspect_ratio);
    return (texcoord.y > b && texcoord.y < (1-b));
  } else {
    // pillarbox
    float b = 0.5 - film_aspect_ratio / (2*aspect_ratio);
    return (texcoord.x > b && texcoord.x < (1-b));
  }
}

/* § Shaders. */

float3 SqueezePS(in float4 _ : SV_Position, in float2 texcoord : TEXCOORD) : SV_Target
{
  if (BUFFER_ASPECT_RATIO < 1)
    discard;

  float2 uv = float2(SqueezeFactor, 1) * texcoord;
  return tex2D(back_buffer, uv).rgb;
}

float3 DesqueezePS(in float4 _ : SV_Position, in float2 texcoord : TEXCOORD) : SV_Target
{
  if (BUFFER_ASPECT_RATIO < 1)
    discard;
  
  float2 uv = float2(1/SqueezeFactor, 1) * texcoord;
  return tex2D(back_buffer, uv).rgb * border(texcoord);
}

technique AnamorphoSqueeze
<
  ui_label = "anamorpho|squeeze [put @ top].";
  ui_tooltip = "The first part (you must use the second) of the anamorphic process simulation program, Anamorpho.\n"
               "For experts, really.\n"
               "Part of the Anagrama shader collection [nullfrctl/reshade-shaders].\n"
               "\n"
               "(C) 2024 Santiago Velasquez. All Rights Reserved.";
>
{
  pass
  {
    VertexShader = PostProcessVS;
    PixelShader  = SqueezePS;
    SRGBWriteEnable = true;
  }
}

technique AnamorphoDesqueeze
<
  ui_label = "anamorpho|desqueeze [put @ bottom].";
  ui_tooltip = "The second part (you must use the first) of the anamorphic process simulation program, Anamorpho.\n"
               "For experts, really.\n"
               "Part of the Anagrama shader collection [nullfrctl/reshade-shaders].\n"
               "\n"
               "(C) 2024 Santiago Velasquez. All Rights Reserved.";
>
{
  pass
  {
    VertexShader = PostProcessVS;
    PixelShader  = DesqueezePS;
    SRGBWriteEnable = true;
  }
}