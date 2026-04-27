#define _XOPEN_SOURCE
#include <locale.h>
#include <time.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

int
main (void)
{
  if (setlocale (LC_ALL, "fi_FI.utf8") == NULL)
    {
      puts ("cannot set locale");
      return 1;
    }
  struct tm tm;
  static const char s[] = "marras";
  char *r = strptime (s, "%b", &tm);
  printf ("r = %p, r-s = %ju, tm.tm_mon = %d\n", r, (uintmax_t)(r - s),
tm.tm_mon);
  return r == NULL || r - s != strlen(s) || tm.tm_mon != 10;
}
