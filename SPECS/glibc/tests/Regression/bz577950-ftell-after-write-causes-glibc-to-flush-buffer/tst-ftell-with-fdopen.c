/* Test case from:
   https://sourceware.org/bugzilla/show_bug.cgi?id=16532#c0 */

#include <assert.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

int
main (int argc, char *argv[])
{
  FILE *fp;
  size_t written;
  off_t off;
  int do_flush = 0, do_fopen = 0;
  int opt;
  const char *const fname = "tst-ftell-with-fdopen.out";

  while ((opt = getopt (argc, argv, "fo")) != -1)
    {
      switch (opt)
        {
        case 'f':
          do_flush = 1;
          break;
        case 'o':
          do_fopen = 1;
          break;
        }
    }

  fp = fopen (fname, "w");
  written = fwrite ("abcabc", 1, 6, fp);
  assert (written == 6);

  fclose (fp);

  if (do_fopen)
    fp = fopen (fname, "a");
  else
    {
      int fd = open (fname, O_WRONLY, 0);
      assert (fd != -1);
      fp = fdopen (fd, "a");
    }

  assert (fp != NULL);

  written = fwrite ("ghi", 1, 3, fp);
  assert (written == 3);

  if (do_flush)
    fflush (NULL);

  off = ftello (fp);
  assert (off == 9);

  return 0;
}
