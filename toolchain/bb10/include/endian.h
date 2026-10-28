/* <endian.h> for BB10 (QNX 8): glibc/BSD-style byte order macros on top of <gulliver.h>. */
#ifndef KO_BB10_ENDIAN_H
#define KO_BB10_ENDIAN_H

#include <gulliver.h>
#include <stdint.h>

#ifndef LITTLE_ENDIAN
#define LITTLE_ENDIAN 1234
#endif
#ifndef BIG_ENDIAN
#define BIG_ENDIAN 4321
#endif
#ifndef PDP_ENDIAN
#define PDP_ENDIAN 3412
#endif
#ifndef BYTE_ORDER
#if defined(__LITTLEENDIAN__)
#define BYTE_ORDER LITTLE_ENDIAN
#else
#define BYTE_ORDER BIG_ENDIAN
#endif
#endif
#define __LITTLE_ENDIAN LITTLE_ENDIAN
#define __BIG_ENDIAN BIG_ENDIAN
#define __BYTE_ORDER BYTE_ORDER

#define htobe16(x) ENDIAN_BE16(x)
#define htole16(x) ENDIAN_LE16(x)
#define be16toh(x) ENDIAN_BE16(x)
#define le16toh(x) ENDIAN_LE16(x)
#define htobe32(x) ENDIAN_BE32(x)
#define htole32(x) ENDIAN_LE32(x)
#define be32toh(x) ENDIAN_BE32(x)
#define le32toh(x) ENDIAN_LE32(x)
#define htobe64(x) ENDIAN_BE64(x)
#define htole64(x) ENDIAN_LE64(x)
#define be64toh(x) ENDIAN_BE64(x)
#define le64toh(x) ENDIAN_LE64(x)

#endif
