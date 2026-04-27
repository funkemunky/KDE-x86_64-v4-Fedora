/* Originally copied from the example at `man 3 backtrace' as supplied by
the Linux man-pages project.  */

#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define SIZE 100

void
last (void)
{
  int j, nptrs;
  void *buffer[SIZE];
  char **strings;

  nptrs = backtrace (buffer, SIZE);

  strings = backtrace_symbols (buffer, nptrs);
  if (strings == NULL)
    {
      perror ("backtrace_symbols");
      exit (EXIT_FAILURE);
    }

  for (j = 0; j < nptrs; j++)
    printf ("%s\n", strings[j]);

  free (strings);
}

static void /* "static" means don't export the symbol... */
penultimate (void)
{
  last ();
}

void
recursive (int ncalls)
{
  if (ncalls > 1)
    recursive (ncalls - 1);
  else
    penultimate ();
}

int
main (int argc, char *argv[])
{
  if (argc != 2)
    {
      fprintf (stderr, "%s num-calls\n", argv[0]);
      exit (EXIT_FAILURE);
    }

  recursive (atoi (argv[1]));
  exit (EXIT_SUCCESS);
}
