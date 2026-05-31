#pragma once

// MinGW/UCRT64 needs a public fixed-width integer typedef for off_type.
#include <stdint.h>

#define _FILE_OFFSET_BITS 64

#ifdef WIN32
#define ftell64(a)     _ftelli64(a)
#define fseek64(a,b,c) _fseeki64(a,b,c)
// __int64_t is not a portable MinGW/UCRT64 type name.
typedef int64_t off_type;
#else
#define ftell64(a)     ftello(a)
#define fseek64(a,b,c) fseeko(a,b,c)
typedef off_t off_type;
#endif
