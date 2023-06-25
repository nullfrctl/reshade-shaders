#include "CSC.fxh"
#include "gamma.fxh"
#include "loathe.fxh"

namespace loathe {
  float3 ps_color(std::vs_t vs) : sv_target {
    float3 color = tex2D(std::backbuffer, vs.texcoord.xy).rgb;
    color = gamma::signal_to_linear(color);

    // float3 XYZ = mul(CSC::RGB_to_XYZ_mat(CSC::chromaticities::xy_to_xyY(CSC::chromaticities::Rec709_xy)), color);
    float3 XYZ = mul(CSC::RGB_to_XYZ_mat(CSC::chromaticities::Rec709_xy), color);
    color = mul(CSC::matrices::XYZ_to_Rec709, XYZ);

    color = gamma::linear_to_signal(color);

    return color;
  }

  technique color < ui_label = "loathe::color";
  > {
    pass {
      PixelShader = ps_color;
      VertexShader = std::vs_quad;
    }
  }
} // namespace loathe