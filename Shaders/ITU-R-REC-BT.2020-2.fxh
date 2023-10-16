#pragma once

namespace BT2020 {

/* Implementation of ITU-R Recommendation BT.2020-2 (2015)
 * "Parameter values for ultra-high definition television systems for 
 * production and international programme exchange" */

// 3 - System colorimetry

// Chromaticity coordinates (CIE, 1931)
static const float3x2 CHROMATICITY_COORDINATES = float3x2(
  0.708, 0.292, // Red primary (R)
  0.170, 0.797, // Green primary (G)
  0.131, 0.046  // Blue primary (B)
);

// Reference white (D65)
static const float2 REFERENCE_WHITE = float2(0.3127, 0.3290);

// 4 - Signal format

/* "...The simultaneous equations provide the required condition to connect the
 * curve segments smoothly and yield a = 1.09929682689044... and 
 * B = 0.018053968510807... */

// Rounded to 32-bit precision limits.
static const float ALPHA = 1.0992968;
static const float BETA = 0.0180540;

/* "In typical production practice the encoding function of image sources is
 * adjusted so that the final picture has the desired look, as viewed on a
 * reference monitor having the reference decoding function of Recommendation
 * ITU-R BT.1886, in the reference viewing environment defined in
 * Recommendation ITU-R BT.2035" */
float3 OETF(float3 E) {
  /* "...where E is voltage normalized by the reference white level and
   * proportional to implicit light intensity that would be detected with a
   * reference camera colour channel R, G, B; E' is the resulting non-linear
   * signal." */

  E = saturate(E);
  float3 Ep;

  Ep = E < BETA
     ? 4.5 * E                              // 0 <= E < B
     : ALPHA * pow(E, 0.45) - (ALPHA - 1.0) // B <= E <= 1

  return saturate(Ep);
}

// Derivation of constant luminance signal Y'_C from camera color channels R,G,B.
float derive_constant_luminance(float3 E) {
  return OETF(dot(E.rgb, float3(0.2627, 0.6780, 0.0593)).xxx).x;
}

// Derivation of non-constant luminance signal Y' from camera color channels R',G',B'.
float derive_luminance(float3 Ep) {
  return dot(Ep.rgb, float3(0.2627, 0.6780, 0.0593));
}

// Derivation of colour difference signals

/* constant difference coming soon, i guess... */

float derive_Cb(float3 Ep) {
  // C'_B = (B' - Y') / 1.8814
  return (Ep.b - derive_luminance(Ep.rgb)) / 1.8814;
}

float derive_Cr(float3 Ep) {
  // C'_R = (R' - Y') / 1.4746
  return (Ep.r - derive_luminance(Ep.rgb)) / 1.4746;
}

// 5 - Digital representation

// Quantization of R', G', B' ,Y' , Y'_C, C'_B, C'_R, C'_BC, C'RC

/* "The operator INT returns the value of 0 for fractional parts in the range of
 * 0 to 0.4999... and +1 for fractional parts in the range of 0.5 to 0.999...,
 * i.e. it rounds up fractions above 0.5." */
float INT(float n) {
  return n >= 0.5 ? ceil(n) : floor(n);
}

/* color difference quantization coming soon, i guess... */

float3 quantize_RGB(float3 Ep, int n) {
  float3 Dp;

  Dp.r = INT((219.0 * Ep.r + 16.0) * exp2(float(n - 8)));
  Dp.g = INT((219.0 * Ep.g + 16.0) * exp2(float(n - 8)));
  Dp.b = INT((219.0 * Ep.b + 16.0) * exp2(float(n - 8)));

  return Dp;
}

static const int2 QUANTIZATION_LEVELS = int2(10, 12);

#define BT2020_10SAMPLER(_name, _texture) sampler2D _name { Texture = _texture; Format = RGB10A2 };
// 12-bit is unavailable in RFX.

}