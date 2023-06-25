// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once
#include "loathe.fxh"

#define sRGB 61966
#define Rec709 709
#define Rec2020 2020

#ifndef DISPLAY_GAMMA
#ifndef _LOATHE_NO_DISP_GAMMA
#define DISPLAY_GAMMA sRGB
#endif
#endif

namespace loathe {
  namespace gamma {
    static const float rcp_24 = 1.0 / 2.4;

    /* Manually computed sRGB constants with higher precision, eliminating the kink at the
     * X/Phi intersection other implementations have. */
    namespace _sRGB {
      float3 EOTF(float3 x) {
        x = saturate(x);
        return std::where(0.03928571429 >= x, x / 12.92321018, pow((x + 0.055) / 1.055, 2.4));
      }

      float3 inverse_EOTF(float3 y) {
        y = saturate(y);
        return std::where(0.00303993464 >= y, y * 12.92321018, 1.055 * pow(y, rcp_24) - 0.055);
      }
    } // namespace _sRGB

#ifdef _LOATHE_NO_DISP_GAMMA
    float3 signal_to_linear(const float3 x) { return x; }
    float3 linear_to_signal(const float3 y) { return y; }
#else
#if DISPLAY_GAMMA == sRGB
    /* `signal_to_linear` is defined as converting the video signal to display linear, not scene linear.
     * This is because sRGB IEC 61966-2-1:1999 does not define an inverse OETF. */
    float3 signal_to_linear(const float3 x) { return _sRGB::EOTF(x); }
    float3 linear_to_signal(const float3 y) { return _sRGB::inverse_EOTF(y); }
#elif DISPLAY_GAMMA == Rec709 || DISPLAY_GAMMA == Rec2020
    float3 signal_to_linear(const float3 x) { return pow(saturate(x), 2.4); }
    float3 linear_to_signal(const float3 y) { return pow(saturate(y), rcp_24); }
#else // custom gamma
    float3 signal_to_linear(const float3 x) { return pow(saturate(x), max(DISPLAY_GAMMA * 0.1, TINY)); }
    float3 linear_to_signal(const float3 y) { return pow(saturate(y), rcp(max(DISPLAY_GAMMA * 0.1, TINY))); }
#endif
#endif
  } // namespace gamma
} // namespace loathe