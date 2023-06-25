// SPDX-License-Identifier: CC-BY-NC-SA-4.0+
#pragma once
#include "loathe.fxh"

namespace loathe {
  namespace CIE_1931 {
    namespace std_illuminants {
      // CCT: 2856
      static const float2 A = float2(0.44757, 0.40745);
      // CCT: 4874
      static const float2 B = float2(0.34842, 0.35161);
      // CCT: 6774
      static const float2 C = float2(0.31006, 0.31616);
      // CCT: 5003
      static const float2 D50 = float2(0.34567, 0.35850);
      // CCT: 5503K
      static const float2 D55 = float2(0.33242, 0.34743);
      // CCT: 6504K
      static const float2 D65 = float2(0.31272, 0.32903);
      // CCT: 7504K
      static const float2 D75 = float2(0.29902, 0.31485);
      // CCT: 9305K
      static const float2 D93 = float2(0.28315, 0.29711);
      // CCT: 5454
      static const float2 E = float2(0.33333, 0.33333);
    } // namespace std_illuminants

    float3 XYZ_to_xyY(const float3 XYZ) {
      const float sum = XYZ.x + XYZ.y;
      float2 xy = saturate(XYZ.xy / sum);

      return float3(xy, XYZ.y);
    }

    float3 xyY_to_XYZ(const float3 xyY) {
      const float Y_y = xyY.z / xyY.y;
      return float3(Y_y * xyY.x, xyY.z, Y_y * (1.0 - xyY.x - xyY.y));
    }

    float xy_to_z(const float2 xy) {
      return (1.0 - xy.x - xy.y);
    }
  } // namespace CIE_1931
} // namespace loathe