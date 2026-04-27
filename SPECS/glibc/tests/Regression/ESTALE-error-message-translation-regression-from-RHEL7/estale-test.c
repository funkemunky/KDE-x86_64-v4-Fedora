#include <stdio.h>
#include <locale.h>
#include <errno.h>

int
main (void)
{
  setlocale (LC_ALL, "");
  errno = ESTALE;
  perror ("ESTALE");
  errno = EAGAIN;
  perror ("EAGAIN");
  return 0;
}
