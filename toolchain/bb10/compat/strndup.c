/* strndup() for BB10 (QNX 8), whose libc lacks it. */
#include <stdlib.h>
#include <string.h>

__attribute__((visibility("hidden")))
char *strndup(const char *s, size_t n)
{
    size_t len = strnlen(s, n);
    char *d = malloc(len + 1);
    if (d) {
        memcpy(d, s, len);
        d[len] = '\0';
    }
    return d;
}
