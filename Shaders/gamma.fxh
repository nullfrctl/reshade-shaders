// SPDX-License-Identifier: CC-BY-NC-SA-4.0+

#include "loathe.fxh"

#define sRGB 61966
#define Rec709 709
#define Rec2020 2020

#ifndef DISPLAY_GAMMA
#define DISPLAY_GAMMA sRGB
#endif

namespace loathe {
  namespace gamma {
    static const float rcp_24 = 1.0 / 2.4;

    namespace _sRGB {
      float3 EOTF(float3 x) {
        x = saturate(x);
        return where(0.03928571429 >= x, x / 12.92321018, pow((x + 0.055) / 1.055, 2.4));
      }

      float3 inverse_EOTF(float3 y) {
        y = saturate(y);
        return where(0.00303993464 >= y, y * 12.92321018, 1.055 * pow(y, rcp_24) - 0.055);
      }
    } // namespace _sRGB

    /* `OETF` is defined as converting the scene linear image to the video signal, and `inverse OETF`
     * is defined as converting the video signal to scene linear, but not display linear. */
    namespace _Rec601 {
      float3 OETF(float3 x) {
        x = saturate(x);
        return where(x < 0.018, 4.5 * x, 1.099 * pow(x, 0.45) - 0.099);
      }

      float3 inverse_OETF(float3 y) {
        y = saturate(y);
        return where(y < 0.081, y / 4.5, pow((y + 0.099) / 1.099, rcp(0.45)));
      }
    } // namespace _Rec601

    /* `video_to_linear` is defined as converting the video signal to display linear, not scene linear.
     * This is because sRGB IEC 61966-2-1:1999 does not define an inverse OETF. */
#if DISPLAY_GAMMA == sRGB
    float3 video_to_linear(const float3 x) { return _sRGB::EOTF(x); }
    float3 linear_to_video(const float3 y) { return _sRGB::inverse_EOTF(y); }
#elif DISPLAY_GAMMA == Rec601 || DISPLAY_GAMMA == Rec709 || DISPLAY_GAMMA == Rec2020
    float3 video_to_linear(float3 x) { return pow(saturate(x), 2.4); }
    float3 linear_to_video(float3 y) { return pow(saturate(y), rcp_24); }
#endif
  } // namespace gamma
} // namespace loathe