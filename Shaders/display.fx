// SPDX-License-Identifier: CC-BY-NC-SA-4.0+

#define _LOATHE_NO_DISP_GAMMA
#include "gamma.fxh"
#include "loathe.fxh"

#ifndef USE_REC601_OETF
#define USE_REC601_OETF 0
#endif

namespace loathe {
  namespace ui {
    uniform uint _ < ui_type = "radio";
    ui_label = " ";
#if USE_REC601_OETF
    ui_text = "\n Rec.709/2020 corresponds to a gamma of 2.4.\n Rec.601 OETF converts to scene linear, not display linear.";
#else
    ui_text = "\n Rec.709/2020 corresponds to a gamma of 2.4.";
#endif
    ui_category = "loathe::display";
    > = 0;

    uniform int input_gamma < ui_type = "combo";
#if USE_REC601_OETF
    ui_items = " sRGB\0 Rec.709/2020\0 Rec.601 inv.OETF\0 Linear\0 Custom\0";
#else
    ui_items = " sRGB\0 Rec.709/2020\0 Linear\0 Custom\0";
#endif
    ui_label = " input display gamma.";
    ui_category = "loathe::display";
    ui_tooltip = "Input display gamma to linearize.\nRec.601 inv.OETF goes to scene, so the inv.OOTF is needed for any gamma than Rec.601 OETF.";
    > = 0;

    uniform int output_gamma < ui_type = "combo";
#if USE_REC601_OETF
    ui_items = " sRGB\0 Rec.709/2020\0 Rec.601 OETF\0 Linear\0 Custom\0";
#else
    ui_items = " sRGB\0 Rec.709/2020\0 Linear\0 Custom\0";
#endif
    ui_label = " output display gamma.";
    ui_category = "loathe::display";
    ui_tooltip = "Input display gamma to re-display.\nRec.601 OETF expects scene, so use the OOTF if you didn't use the Rec.601 inv.OETF.";
    > = 0;

#if USE_REC601_OETF
    uniform bool forward_OOTF < ui_label = " apply forward OOTF.";
    ui_spacing = 3;
    ui_category = "loathe::display";
    ui_tooltip = "The forward OOTF converts scene linear to display linear.";
    > = false;

    uniform bool inverse_OOTF < ui_label = " apply inverse OOTF.";
    ui_category = "loathe::display";
    ui_tooltip = "The inverse OOTF converts display linear to scene linear.";
    > = false;
#endif

    uniform float custom_gamma < ui_type = "drag";
    ui_spacing = 3;
    ui_label = " custom gamma.";
    ui_category = "loathe::display";
    ui_tooltip = "Some displays will use 1.8, some plain 2.2.\nThis is for those rare cases.";
    ui_min = 1.0;
    > = 1.8;
  } // namespace ui

#if USE_REC601_OETF
  /* `OETF` is defined as converting the scene linear image to the video signal, and `inverse OETF`
   * is defined as converting the video signal to scene linear, but not display linear. */
  float3 Rec601_OETF(float3 x) {
    x = saturate(x);
    return where(x < 0.018, 4.5 * x, 1.099 * pow(x, 0.45) - 0.099);
  }

  float3 inverse_Rec601_OETF(float3 y) {
    y = saturate(y);
    return where(y < 0.081, y / 4.5, pow((y + 0.099) / 1.099, rcp(0.45)));
  }
#endif

  float3 Rec709_EOTF(float3 x) {
    return pow(x, 2.4);
  }

  float3 inverse_Rec709_EOTF(float3 y) {
    return pow(y, gamma::rcp_24);
  }

  float3 ps_main(vs_t vs) : sv_target {
    float3 color = saturate(tex2D(backbuffer, vs.texcoord.xy).rgb);

    if (all(color == 0.0) || all(color == 1.0) || ui::input_gamma == ui::output_gamma) {
      discard;
    }

    [branch] switch (ui::input_gamma) {
    case 0: // sRGB
      color = gamma::_sRGB::EOTF(color);
      break;
    case 1: // Rec709/2020
      color = Rec709_EOTF(color);
      break;
#if USE_REC601_OETF
    case 2: // Rec601
      color = inverse_Rec601_OETF(color);
      break;
    case 3: // linear
      break;
#else
    case 2: // linear
      break;
#endif
    default: // custom gamma
      color = pow(color, max(ui::custom_gamma, TINY));
      break;
    }

#if USE_REC601_OETF
    /* This converts the scene linear values of the Rec.601 inverse OETF to display
     * linear ones that can be used with inverse EOTFs */
    if (ui::forward_OOTF) {
      color = Rec709_EOTF(Rec601_OETF(color));
    }

    /* The inverse OOTF converts display linear values out of the sRGB and Rec.709/2020
     * input transforms to scene linear values that can be handled by OETFs */
    if (ui::inverse_OOTF) {
      color = inverse_Rec601_OETF(inverse_Rec709_EOTF(color));
    }
#endif

    [branch] switch (ui::output_gamma) {
    case 0: // sRGB
      color = gamma::_sRGB::inverse_EOTF(color);
      break;
    case 1: // Rec709/2020
      color = inverse_Rec709_EOTF(color);
      break;
#if USE_REC601_OETF
    case 2: // Rec601
      color = Rec601_OETF(color);
      break;
    case 3: // linear
      break;
#else
    case 2: // linear
      break;
#endif
    default: // custom gamma
      color = pow(color, max(rcp(ui::custom_gamma), TINY));
      break;
    }

    return color;
  }

  technique loathe_display < ui_label = "loathe::display";
  ui_tooltip = "Display transforms between input gamma and output gamma.";
  > {
    pass {
      PixelShader = ps_main;
      VertexShader = vs_quad;
    }
  }
} // namespace loathe