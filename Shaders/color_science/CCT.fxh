// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once
#include "loathe.fxh"

#ifndef CCT_ENFORCE_DOMAIN
#define CCT_ENFORCE_DOMAIN 1
#endif

#if CCT_ENFORCE_DOMAIN
#define _CCT_CONST
#else
#define _CCT_CONST const
#endif

namespace CCT {
  /* https://colour.readthedocs.io/en/develop/_modules/colour/temperature/cie_d.html#CCT_to_xy_CIE_D
   * Domain is 4000K–25000K. */
  static const int2 CIE_D_domain = int2(4000, 25000);
  float2 K_to_xy_CIE_D(_CCT_CONST float CCT) {
#if CCT_ENFORCE_DOMAIN
    CCT = clamp(CCT, CIE_D_domain.x, CIE_D_domain.y);
#endif

    const float CCT_2 = CCT * CCT;
    const float CCT_3 = CCT_2 * CCT;
    float2 xy;

    [flatten] if (CCT <= 7000) {
      xy.x = -4.607 * 1e+9 / CCT_3 + 2.9678 * 1e+6 / CCT_2 + 0.09911 * 1e+3 / CCT + 0.244063;
    }
    else {
      xy.x = -2.0064 * 1e+9 / CCT_3 + 1.9018 * 1e+6 / CCT_2 + 0.24748 * 1e+3 / CCT + 0.23704;
    }

    /* https://colour.readthedocs.io/en/develop/_modules/colour/colorimetry/illuminants.html#daylight_locus_function */
    xy.y = -3.0 * xy.x * xy.x + 2.87 * xy.x - 0.275;

    return xy;
  }

  /* https://colour.readthedocs.io/en/develop/_modules/colour/temperature/kang2002.html#CCT_to_xy_Kang2002
   * Domain is 1667K–25000K. */
  static const int2 Kang2002_domain = int2(1667, 25000);
  float2 K_to_xy_Kang2002(_CCT_CONST float CCT) {
#if CCT_ENFORCE_DOMAIN
    CCT = clamp(CCT, Kang2002_domain.x, Kang2002_domain.y);
#endif

    const float CCT_2 = CCT * CCT;
    const float CCT_3 = CCT_2 * CCT;

    float x;
    [flatten] if (CCT <= 4000) {
      x = -0.2661239 * 1e+9 / CCT_3 - 0.2343589 * 1e+6 / CCT_2 + 0.8776956 * 1e+3 / CCT + 0.179910;
    }
    else {
      x = -3.0258469 * 1e+9 / CCT_3 + 2.1070379 * 1e+6 / CCT_2 + 0.2226347 * 1e+3 / CCT + 0.24039;
    }

    float x_2 = x * x;
    float x_3 = x_2 * x;

    float y;
    [flatten] if (CCT <= 2222) {
      y = -1.1063814 * x_3 - 1.34811020 * x_2 + 2.18555832 * x - 0.20219683;
    }
    else if (CCT > 2222 && CCT <= 4000) {
      y = -0.9549476 * x_3 - 1.37418593 * x_2 + 2.09137015 * x - 0.16748867;
    }
    else {
      y = 3.0817580 * x_3 - 5.8733867 * x_2 + 3.75112997 * x - 0.37001483;
    }

    return float2(x, y);
  }
} // namespace CCT