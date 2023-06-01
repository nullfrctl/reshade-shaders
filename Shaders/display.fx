// SPDX-License-Identifier: CC-BY-NC-SA-4.0+

#include "gamma.fxh"
#include "loathe.fxh"

namespace loathe {
  namespace ui {
    uniform uint _ < ui_type = "radio";
    ui_label = " ";
    ui_text = "\n Rec.709/2020 corresponds to a gamma of 2.4.\n Rec.601 OETF converts to scene linear, not display linear.";
    ui_category = "loathe::display";
    > = 0;

    uniform uint input_gamma < ui_type = "combo";
    ui_items = " sRGB\0 Rec.709/2020\0 Rec.601 inv.OETF\0 Linear\0 Custom\0";
    ui_label = " input display gamma.";
    ui_category = "loathe::display";
    ui_tooltip = "Input display gamma to linearize.\nRec.601 inv.OETF goes to scene, so the inv.OOTF is needed for any gamma than Rec.601 OETF.";
    > = 0;

    uniform uint output_gamma < ui_type = "combo";
    ui_items = " sRGB\0 Rec.709/2020\0 Rec.601 OETF\0 Linear\0 Custom\0";
    ui_label = " output display gamma.";
    ui_category = "loathe::display";
    ui_tooltip = "Input display gamma to re-display.\nRec.601 OETF expects scene, so use the OOTF if you didn't use the Rec.601 inv.OETF.";
    > = 0;

    uniform bool forward_OOTF < ui_label = " apply forward OOTF.";
    ui_spacing = 3;
    ui_category = "loathe::display";
    ui_tooltip = "The forward OOTF converts scene linear to display linear.";
    > = false;

    uniform bool inverse_OOTF < ui_label = " apply inverse OOTF.";
    ui_category = "loathe::display";
    ui_tooltip = "The inverse OOTF converts display linear to scene linear.";
    > = false;

    uniform float custom_gamma < ui_type = "drag";
    ui_spacing = 3;
    ui_label = " custom gamma.";
    ui_category = "loathe::display";
    ui_tooltip = "Some displays will use 1.8, some plain 2.2.\nThis is for those rare cases.";
    ui_min = 1.0;
    > = 1.8;
  } // namespace ui

  float3 ps_main(vs_t vs) : sv_target {
    float3 color = saturate(tex2D(backbuffer, vs.texcoord.xy).rgb);

    switch (ui::input_gamma) {
    case 0: // sRGB
      color = gamma::_sRGB::EOTF(color);
      break;
    case 1: // Rec709/2020
      color = pow(color, 2.4);
      break;
    case 2: // Rec601
      color = gamma::_Rec601::inverse_OETF(color);
      break;
    case 3: // linear
      break;
    default: // custom gamma
      color = pow(color, max(ui::custom_gamma, TINY));
      break;
    }

    /* This converts the scene linear values of the Rec.601 inverse OETF to display
     * linear ones that can be used with inverse EOTFs */
    if (ui::forward_OOTF) {
      color = pow(gamma::_Rec601::OETF(color), 2.4);
    }

    /* The inverse OOTF converts display linear values out of the sRGB and Rec.709/2020
     * input transforms to scene linear values that can be handled by OETFs */
    if (ui::inverse_OOTF) {
      color = gamma::_Rec601::inverse_OETF(pow(color, gamma::rcp_24));
    }

    switch (ui::output_gamma) {
    case 0: // sRGB
      color = gamma::_sRGB::inverse_EOTF(color);
      break;
    case 1: // Rec709/2020
      color = pow(color, gamma::rcp_24);
      break;
    case 2: // Rec601
      color = gamma::_Rec601::OETF(color);
      break;
    case 3: // linear
      break;
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