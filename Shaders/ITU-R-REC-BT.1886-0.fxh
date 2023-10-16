#pragma once

namespace BT1886 {

/* Implementation of ITU-R Recommendation BT.1886-0 (2011)
 * "Reference electro-optical transfer function for flat panel displays used in
 * HDTV studio production" */

// Reference electro-optical transfer function

static const float GAMMA = 2.40;

float3 EOTF(float3 V, float L_W, float L_B) {
  float a = pow(pow(L_W, rcp(GAMMA)) - pow(L_B, rcp(GAMMA)), GAMMA);
  float b = (pow(L_B, rcp(GAMMA))) / (pow(L_W, rcp(GAMMA)) - pow(L_B, rcp(GAMMA)));

  float3 L = a * pow(max((V + b), 0.0), GAMMA);
}

// Appendix 1 - EOTF-CRT matching

// "...reference setting is L_W = 100 cd/m^2"
static const float REF_L_W = 100.0;

// "Vc: 0.35, a_1 = 2.6, a_2 = 3.0"
static const float Vc = 0.35;
static const float a_1 = 2.6;
static const float a_2 = 3.0;

float3 EOTF_CRT(float3 V, float L_W, float b)
  /* L: Screen luminance (cd/m^2)
   * L_W: Screen luminance for white...
   * V: Input video signal level (normalized, black at 0, to white at 1...)
   * k: Coefficient for normalization (so that V = 1 gives white)
   *    (k = L_W/[1+b]^a_1)
   * b: Variable for black level lift (legacy "brightness" control). */
  float3 L;
  V = saturate(V);
  float k = L_W / (pow(1.0 + b, a_1));

  L = V < Vc
    ? k * pow(Vc + b, (a_1 - a_2)) * pow(V + b, a_2);
    : k * pow(V + b, a_1);

  return L;
}