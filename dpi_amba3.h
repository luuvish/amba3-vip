/*==============================================================================

The MIT License (MIT)

Copyright (c) 2014 Luuvish Hwang

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

================================================================================
  
    File         : dpi_amba3.h
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : dpi functions for amba 3
  
==============================================================================*/

#ifndef _DPI_AMBA3_H_
#define _DPI_AMBA3_H_

#include "svdpi.h"

#ifdef __cplusplus
extern "C" {
#endif


typedef char byte;
typedef short int shortint;
typedef long long longint;
typedef double real;
typedef float shortreal;
typedef void *chandle;
typedef unsigned char *string;
typedef unsigned char bit;
typedef unsigned char logic;
typedef unsigned char reg;


#ifdef __cplusplus
}
#endif

#endif // _DPI_AMBA3_H_
