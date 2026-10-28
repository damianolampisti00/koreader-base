/* <byteswap.h> for BB10 (QNX 8). */
#ifndef KO_BB10_BYTESWAP_H
#define KO_BB10_BYTESWAP_H

#define bswap_16(x) __builtin_bswap16(x)
#define bswap_32(x) __builtin_bswap32(x)
#define bswap_64(x) __builtin_bswap64(x)

#endif
