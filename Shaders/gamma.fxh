// SPDX-License-Identifier: CC-BY-NC-SA-4.0+

/* License for sRGB, Rec709, Cineon Log transfer functions: 
<<
Copyright 2013 Colour Developers
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Colour Developers nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL COLOUR DEVELOPERS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
>> 
*/ 

#pragma once
#include "loathe.fxh"

#define __preprocessor_help_text__ \
"Display gamma can be ITU or IEC specification name (e.g. sRGB, Rec709)" _n \
"or number (e.g. 61966, 709)." _n \
_n \
"You can also input a custom gamma through a 2-digit " _n \
"number (e.g. 24 for 2.4, 10 for 1.0/linear)" _n \
_n \
"Currently only sRGB (61966) and Rec709 (709) are implemented" _n \
"If you use a TV, input 'Rec709'. If you use a monitor, input 'sRGB'."

// gamma for display.
#define sRGB 61966 // IEC 61966-2-1:1999
#define Rec709 709 // ITU-R BT.709

#ifndef DISPLAY_GAMMA
  #define DISPLAY_GAMMA sRGB // can also be Rec709
#endif

namespace loathe
{

namespace _sRGB
{
float3 inverse_EOTF(float3 y)
{
  y = abs(y);
  float3 x = y <= 0.0031308 ? y * 12.9232102 : 1.055 * pow(y, rcp(2.4)) - 0.055;
  return x;
}

float3 EOTF(float3 x)
{
  x = abs(x);
  float3 y = inverse_EOTF(0.0031308) >= x ? x / 12.9232102 : pow((x + 0.055) / 1.055, 2.4);
  return y;
}
}

namespace _Rec709
{

float3 OETF(float3 L)
{
  L = abs(L);
  float3 V = L < 0.018053968510807 ? L * 4.5 : 1.099296826809442 * pow(L, rcp(2.2)) - 0.099296826809442;

  return V;
}

float3 inverse_OETF(float3 V)
{
  V = abs(V);
  // controversial: maybe 0.18, maybe 0.81...
  float3 L = V < (0.018053968510807 * 4.5) ? V / 4.5 : pow((V + 0.099296826809442) / 1.099296826809442, 2.2);

  return L;
}

}

namespace gamma
{
#if (DISPLAY_GAMMA == sRGB)
  float3 signal_to_linear(float3 x) { return ::loathe::_sRGB::EOTF(x); }
  float3 linear_to_signal(float3 x) { return ::loathe::_sRGB::inverse_EOTF(x); }
#elif (DISPLAY_GAMMA == Rec709)
  float3 signal_to_linear(float3 x) { return ::loathe::_Rec709::inverse_OETF(x); }
  float3 linear_to_signal(float3 x) { return ::loathe::_Rec709::OETF(x); }
#else
  float3 signal_to_linear(x) { return pow(x, DISPLAY_GAMMA * 0.1); }
  float3 linear_to_signal(x) { return pow(x, rcp(DISPLAY_GAMMA * 0.1)); }
#endif
}

namespace log
{

// precalculated in python. only use to get 100% accurate cineon log, otherwise useless.
static const float cineon_black_offset = 0.0107977516232771;

float3 encode_cineon(float3 x, float black_offset)
{
  float3 y = (685.0 + 300.0 * log10(x * (1.0 - black_offset) + black_offset)) / 1023.0;

  return y;
}

float3 encode_cineon(float3 x)
{
  return encode_cineon(x, 0.0);
}

float3 decode_cineon(float3 y, float black_offset)
{
  float3 x = pow(10.0, ((1023.0 * y - 685.0) / 300.0) - black_offset) / (1.0 - black_offset);

  return x;
}

float3 decode_cineon(float3 x)
{
  return decode_cineon(x, 0.0);
}

}

}