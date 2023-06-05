// SPDX-License-Identifier: CC-BY-NC-SA-4.0+
#include "loathe.fxh"

namespace loathe {
  namespace log {
    namespace cineon {
      static const float _black_offset = 0.0108;

      // SPDX-License-Identifier: BSD-3-Clause
      float3 encode(const float3 x, const float black_offset) {
        float3 y = (685.0 + 300.0 * log10(x * (1.0 - black_offset) + black_offset)) / 1023.0;
        return saturate(y);
      }

      // SPDX-License-Identifier: BSD-3-Clause
      float3 encode(const float3 x) {
        float3 y = (685.0 + 300.0 * log10(x * (1.0 - _black_offset) + _black_offset)) / 1023.0;
        return saturate(y);
      }

      // SPDX-License-Identifier: BSD-3-Clause
      float3 decode(const float3 y, const float black_offset) {
        float3 x = exp10(((1023.0 * y - 685.0) / 300.0) - black_offset) / (1 - black_offset);
        return saturate(x);
      }

      // SPDX-License-Identifier: BSD-3-Clause
      float3 decode(const float3 y) {
        float3 x = exp10(((1023.0 * y - 685.0) / 300.0) - _black_offset) / (1 - _black_offset);
        return saturate(x);
      }
    } // namespace cineon
  }   // namespace log
} // namespace loathe