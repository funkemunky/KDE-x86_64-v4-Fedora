/* A reproducer from https://sourceware.org/bugzilla/show_bug.cgi?id=15362.  */

#include <errno.h>
#include <error.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <signal.h>
#include <stdlib.h>

#define CATCH_SIGSEGV 0
#define FILESIZE (32 * 1024 * 1024)

static void *buf;

static void
sigsegv_handler (int signo, siginfo_t * info, void *context)
{
  printf ("Caught SIGSEGV at address %p (buf + %lu)\n",
          info->si_addr, (void *) info->si_addr - buf);
  abort ();
}

#define handle_error(msg) error(1, errno, msg)

int
main (int argc, char *argv[])
{
  FILE *fp;
  size_t bytes_written;
  int ret;
  struct sigaction sa;
  char * filepath;

  if (argc != 2)
    handle_error ("Invalid number of arguments\n");

  filepath = argv[1];

  buf = mmap (NULL, FILESIZE + 4096, PROT_READ | PROT_WRITE,
              MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);
  if (buf == MAP_FAILED)
    handle_error ("mmap_failed");

  ret = mprotect (buf + FILESIZE, 4096, PROT_NONE);
  if (ret == -1)
    handle_error ("mprotect failed");

  memset (buf, 0, FILESIZE);

  fp = fopen (filepath, "wb");
  if (!fp)
    handle_error ("fopen(...) failed");

  memset (&sa, 0, sizeof (sa));
  sa.sa_sigaction = sigsegv_handler;
  sa.sa_flags = SA_SIGINFO;
#if CATCH_SIGSEGV
  sigaction (SIGSEGV, &sa, NULL);
#endif
  bytes_written = fwrite (buf, 1, FILESIZE, fp);
  printf ("fwrite(): bytes_written = %zu (errno: %m)\n", bytes_written);
  return 0;
}
