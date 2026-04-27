#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#define MEGABYTE 1048576
#define KILOBYTE 1024

/* How to call:
   ./tst-write-ftell DESTFILE SIZE_KB 0|1

   0 => do not call ftell;
   1 => call ftell;
   
   SIZE_KB must be in range [10,200].  */

int
main (int argc, char *argv[])
{
  int ret;
  char *filename;
  char *data;
  int dsize, writesize, chunksize, count;
  FILE *file;

  int ftell_on = 0;
  chunksize = 208;

  if (argc < 3)
    {
      fprintf (stderr, "Invalid arguments\n");
      exit (1);
    }

  filename = argv[1];

  errno = 0;
  dsize = strtol (argv[2], NULL, 0);
  if (errno)
    {
      perror ("strtol() failed");
      return 1;
    }
  if ((dsize < 10)
      || (dsize > 200))
    {
      fprintf (stderr, "Invalid SIZE_KB: %d\n", dsize);
      exit (1);
    }
  dsize *= KILOBYTE;

  ftell_on = strtol (argv[3], NULL, 0);
  if (errno)
    {
      perror ("strtol() failed");
      exit (1);
    }

  data = malloc (sizeof (char) * dsize);
  if (!data)
    {
      perror ("malloc() failed");
      exit (1);
    }

  file = fopen (filename, "w");
  if (file == NULL)
    {
      perror ("fopen failed()");
      exit (1);
    }

  for (count = 0; count < dsize; count += chunksize)
    {
      if (count + chunksize <= dsize)
        {
          writesize = chunksize;
        }
      else
        {
          writesize = dsize - count;
        }

      ret = fwrite (data, writesize, 1, file);

      if (ret != 1)
        {
          perror ("Write failed");
          abort ();
        }

      if (ftell_on)
        {
          int pos;
          pos = ftell (file);
          if (pos < 0)
            {
              perror ("ftell() failed");
              abort ();

            }
        }

    }
  ret = fclose (file);
}
