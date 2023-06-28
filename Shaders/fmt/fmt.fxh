// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once
#include "utf_8.fxh"

#define FMT_WRAP(_str, _wrap) _wrap _str _wrap
#define DOUBLE(_c) _c _c
#define STRINGIZE(_str) #_str

#define LF "\n"
#define EXTENDED_LF FMT_WRAP(LF, SPACE)

#ifdef FMT_EXTENDED_NEWLINE
#define NL EXTENDED_LF
#else
#define NL LF
#endif

#define BT NL