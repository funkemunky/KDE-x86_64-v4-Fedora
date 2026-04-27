#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <netdb.h>
#include <string.h>
#include <stdlib.h>

#define SIZE 4096

#define exit_code_func_msg(c,f,m)             \
  do                                          \
    {                                         \
      printf ("error %d: %s: %s\n", c, f, m); \
      exit (1);                               \
    }                                         \
  while (0)

static void
get_canon_name (char *hostname, int af)
{
  struct addrinfo hints, *result, *current;
  int error;

  memset (&hints, 0, sizeof (hints));
  hints.ai_family = af;
  hints.ai_socktype = SOCK_DGRAM;
  hints.ai_flags = AI_CANONNAME;

  error = getaddrinfo (hostname, NULL, &hints, &result);

  if (error != 0)
    exit_code_func_msg (error, "getaddrinfo", gai_strerror (error));

  if (result->ai_canonname == NULL)
    exit_code_func_msg (-1, "getaddrinfo", "No canonical name returned");

  for (current = result;
       current != NULL && current->ai_canonname != NULL;
       current = current->ai_next)
    printf ("%s\n", current->ai_canonname);

  freeaddrinfo (result);

  return;
}

int
main (int argc, char **argv)
{

  char hostname[SIZE];
  int error;

  error = gethostname (hostname, SIZE);

  if (error)
    exit_code_func_msg (error, "gethostname", "");

  printf ("%s\n", hostname);

  get_canon_name (hostname, AF_INET);
  get_canon_name (hostname, AF_INET6);
  get_canon_name (hostname, AF_UNSPEC);

  return 0;
}
