// SPDX-License-Identifier: CC-BY-NC-SA-4.0+
#pragma once
#include "loathe.fxh"

namespace loathe
{
  namespace depth
  {
    float get_depth(float2 texcoord, float far_plane)
    {
      // vflip depth.
      #if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
      texcoord.y = 1.0 - texcoord.y;
      #endif

      // scale depth.
      #if (RESHADE_DEPTH_INPUT_X_SCALE && RESHADE_DEPTH_INPUT_Y_SCALE)
      texcoord.xy /= float2(RESHADE_DEPTH_INPUT_X_SCALE, RESHADE_DEPTH_INPUT_Y_SCALE);
      #endif

      // pixel offsets.
      #if (RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET)
      texcoord.x -= RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET * BUFFER_RCP_WIDTH;
      #else
      texcoord.x -= RESHADE_DEPTH_INPUT_X_OFFSET * 0.5;
      #endif

      #if (RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET)
      texcoord.x -= RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET * BUFFER_RCP_HEIGHT;
      #else
      texcoord.x -= RESHADE_DEPTH_INPUT_Y_OFFSET * 0.5;
      #endif

      float depth = tex2Dlod(depthbuffer, float4(texcoord.xy, 0, 0)).x;

      // multiplier
      #if (RESHADE_DEPTH_MULTIPLIER)
    	depth *= RESHADE_DEPTH_MULTIPLIER;
    	#endif

      // logarithmic depth.
      #if (RESHADE_DEPTH_INPUT_IS_LOGARITHMIC)
      depth = (exp(depth * log(0.01 + 1.0)) - 1.0) * 100.0;
      #endif

      // reverse depth.
      #if (RESHADE_DEPTH_INPUT_IS_REVERSED)
      depth = 1.0 - depth;
      #endif

      depth /= far_plane - depth * (far_plane - 1.0);

      return depth;
    }

    float get_depth(float2 texcoord)
    {
      return get_depth(texcoord.xy, RESHADE_DEPTH_LINEARIZATION_FAR_PLANE);
    }
  } // namespace depth
} // namespace loathe