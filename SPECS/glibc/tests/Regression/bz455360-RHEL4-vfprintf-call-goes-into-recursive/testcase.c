#include <stdio.h>
#include <string.h>
#include <unistd.h>

int
main (void)
{
  char str[8192+2048];
  memset (str, 'A', sizeof (str) - 1);
  str[sizeof (str) - 1] = '\0';
  FILE *f = fopen ("abcd", "w");
  setvbuf (f, NULL, _IONBF, 0);
  /* Force error on next overflow.  */
  close (fileno (f));
  fprintf (f, "%s\n", str);
  return 0;
}
