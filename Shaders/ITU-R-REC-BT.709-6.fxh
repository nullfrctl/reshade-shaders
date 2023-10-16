#pragma once

namespace BT709 {

/* Implementation of ITU-R Recommendation BT.709-6 (2015)
 * "Parameter values for the HDTV standards for production and international
 * programme exchange" */

// 1 - Opto-electronic conversion: Scene linear to signal

/* "In typical production practice the encoding function of image sources is"
 * adjusted so that the final picture has the desired look, as viewed on a
 * reference monitor having the reference decoding function of Recommendation
 * ITU-R BT.1886, in the reference viewing environment defined in
 * Recommendation ITU-R BT.2035" */
float3 OETF(float3 L) {
  // L: luminance of the image 0 <= L <= 1
  // V: corresponding electrical signal

  L = saturate(L);
  float3 V;

  V = L >= 0.018
    ? 1.099 * pow(L, 0.45) - 0.099 // for 1 >= L >= 0.018
    : 4.500 * L;                   // for 0.018 > L >= 0

  return saturate(V);
}

// Chromaticity coordinates (CIE, 1931)
static const float3x2 CHROMATICITY_COORDINATES = float3x2(
  0.640, 0.330, // Red (R)
  0.300, 0.600, // Green (G)
  0.150, 0.060  // Blue (B)
);

// Assumed chromaticity for equal primary signals (Reference white, D65)
// E_R = E_G = E_B
static const float2 REFERENCE_WHITE = float2(0.3127, 0.3290);

// 3 - Signal format

// Conceptual non-linear pre-correction of primary signals
static const float GAMMA = 0.45

// Derivation of luminance signal E'_Y
float derive_luminance(float3 Ep) {
  // E'_Y = 0.2126*E'_R + 0.7152*E'_G + 0.0722*E'_B
  return dot(Ep.rgb, float3(0.2126, 0.7152, 0.0722));
}

// Derivation of colour-difference signal (analogue coding)

float derive_Cb(float3 Ep) {
  // E'_CB = (E'_B - E'Y) / 1.8556
  //       = (-0.2126*E'_R - 0.7152*E'_G + 0.9278*E'_B) / 1.8556
  return dot(Ep.rgb, float3(-0.2126, -0.7152, 0.9278)) / 1.8556;
}

float derive_Cr(float3 Ep) {
  // E'_CR = (E'_R - E'_Y) / 1.5748
  //       = (0.7874*E'_R - 0.7152*E'_G - 0.0722*E'_B) / 1.5748
  return dot(Ep.rgb, float3(0.7874, -0.7152, -0.0722)) / 1.5748;
}

// Quantization of RGB, luminance, and colour-difference signals.

/* "The operator INT returns the value of 0 for fractional parts in the range of
 * 0 to 0.4999... and +1 for fractional parts in the range of 0.5 to 0.999...,
 * i.e. it rounds up fractions above 0.5." */
float INT(float n) {
  return n >= 0.5 ? ceil(n) : floor(n);
}

/* "'n' denotes the number of the bit length of the quantized signal" */

float3 quantize_RGB(float3 Ep, int n) {
  float3 Dp;

  Dp.r = INT((219.0 * Ep.r + 16.0) * exp2(float(n - 8)));
  Dp.g = INT((219.0 * Ep.g + 16.0) * exp2(float(n - 8)));
  Dp.b = INT((219.0 * Ep.b + 16.0) * exp2(float(n - 8)));

  return Dp;
}

float3 quantize_YCbCr(float3 Ep, int n) {
  float3 Dp;

  // D'_Y
  Dp.x = INT((219.0 * Ep.x + 16.0) * exp2(float(n - 8)));

  // D'_CB
  Dp.y = INT((224.0 * Ep.y + 128.0) * exp2(float(n - 8)));

  // D'_CR
  Dp.z = INT((224.0 * Ep.z + 128.0) * exp2(float(n - 8)));

  return Dp;
}

float3 derive_quantized_YCbCr(float3 Dp, int n) {
  float3 Dp;

  // D'_Y
  Dp.x = INT(derive_luminance(Dp.rgb));

  // D'_CB
  Dp.y = INT(derive_Cb(Dp.rgb) * (224.0 / 219.0) + exp2(n - 1));

  // D'_CR
  Dp.z = INT(derive_Cr(Dp.rgb) * (224.0 / 219.0) + exp2(n - 1));

  return Dp;
}

// 4 - Digital representation

static const int2 QUANTIZATION_LEVELS = int2(8, 10);

#define BT709_8SAMPLER(_name, _texture) sampler2D _name { Texture = _texture; Format = RGBA8; }
#define BT709_10SAMPLER(_name, _texture) sampler2D _name { Texture = _texture; Format = RGB10A2; }

}