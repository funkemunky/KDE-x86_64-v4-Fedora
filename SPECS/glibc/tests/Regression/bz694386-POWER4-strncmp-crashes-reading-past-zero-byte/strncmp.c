#define __NO_STRING_INLINES
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>

int
main (void)
{
  char *p1;
  int ps = getpagesize ();

  p1 = mmap (0, ps * 2, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
  mprotect (p1 + ps, ps, PROT_NONE);
  p1 += ps - 10;
  strcpy (p1, "123456789");
  return (strncmp (p1, "1234567890", 11) == 0
	  || strncmp ("1234567890", p1, 11) == 0);
}
