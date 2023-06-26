// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once
#include "CIE_1931.fxh"
#include "loathe.fxh"

namespace CAT {
  static const float3x3 M_XYZ = float3x3(1.0, 0.0, 0.0,
                                         0.0, 1.0, 0.0,
                                         0.0, 0.0, 1.0);

  static const float3x3 inv_M_XYZ = float3x3(1.0, 0.0, 0.0,
                                             0.0, 1.0, 0.0,
                                             0.0, 0.0, 1.0);

  static const float3x3 M_Bradford = float3x3(+0.8951000, +0.2664000, -0.1614000,
                                              -0.7502000, +1.7135000, +0.0367000,
                                              +0.0389000, -0.0685000, +1.0296000);

  static const float3x3 inv_M_Bradford = float3x3(+0.9869929, -0.1470543, +0.1599627,
                                                  +0.4323053, +0.5183603, +0.0492912,
                                                  -0.0085287, +0.0400428, +0.9684867);

  static const float3x3 M_von_Kries = float3x3(+0.4002400, +0.7076000, -0.0808100,
                                               -0.2263000, +1.1653200, +0.0457000,
                                               +0.0000000, +0.0000000, +0.9182200);

  static const float3x3 inv_M_von_Kries = float3x3(+1.8599364, -1.1293816, +0.2198974,
                                                   +0.3611914, +0.6388125, -0.0000064,
                                                   +0.0000000, +0.0000000, +1.0890636);

  float3x3 basic_adaptation_matrix(const float3 source_XYZ, const float3 destination_XYZ, const float3x3 CAT_M, const float3x3 inv_CAT_M) {
    float3 source_LMS = mul(CAT_M, source_XYZ);
    float3 destination_LMS = mul(CAT_M, destination_XYZ);
    float3x3 x = std::diag(destination_LMS / source_LMS);

    return mul(inv_CAT_M, mul(x, CAT_M));
  }

  float3 XYZ_scaling(const float2 source_white, const float2 destination_white, const float3 XYZ) {
    float3 source_XYZ = CIE_1931::xyY_to_XYZ(float3(source_white, 1.0));
    float3 destination_XYZ = CIE_1931::xyY_to_XYZ(float3(destination_white, 1.0));

    return (destination_XYZ / source_XYZ) * XYZ;
  }

  float3 Bradford(const float2 source_white, const float2 destination_white, float3 XYZ) {
    float3 source_XYZ = CIE_1931::xyY_to_XYZ(float3(source_white, 1.0));
    float3 destination_XYZ = CIE_1931::xyY_to_XYZ(float3(destination_white, 1.0));

    return mul(basic_adaptation_matrix(source_XYZ, destination_XYZ, M_Bradford, inv_M_Bradford), XYZ);
  }

  float3 von_Kries(const float2 source_white, const float2 destination_white, float3 XYZ) {
    float3 source_XYZ = CIE_1931::xyY_to_XYZ(float3(source_white, 1.0));
    float3 destination_XYZ = CIE_1931::xyY_to_XYZ(float3(destination_white, 1.0));

    return mul(basic_adaptation_matrix(source_XYZ, destination_XYZ, M_von_Kries, inv_M_von_Kries), XYZ);
  }
} // namespace CAT