#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

int main()
{
    char *buf, *buf2;

    buf = (char*)mmap((void*)0x100000000, 0x2000 * 2,
                      PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    buf = mmap((char *)buf, 0x2000, PROT_READ | PROT_WRITE,
               MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0);
    memset(buf, 'a', 0x2000);
    buf[0x1fff] = 0;
    buf2 = strdup(buf);
    if (strncmp (buf + 3994, buf2 + 2635, 6241) >= 0)
      abort ();

    return 0;
}
