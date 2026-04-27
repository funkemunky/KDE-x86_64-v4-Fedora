#define _BSD_SOURCE
#include <unistd.h>
#include <sys/socket.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SIZE 500

/* Calls getaddrinfo thrice with argv[1]
i.e. once each for AF_UNSPEC, AF_INET and AF_INET6
*/

void
test (char *query, int af, char *af_name)
{
  struct addrinfo *result, *current;
  struct addrinfo hints;
  int ecode;

  hints.ai_socktype = 0;
  hints.ai_protocol = 0;
  hints.ai_flags = AI_CANONNAME|AI_ADDRCONFIG;
  hints.ai_family = af;

  if (ecode = getaddrinfo (query, NULL, &hints, &result))
    {
      printf ("WARN: %s query failed with error: %s\n", af_name, gai_strerror(ecode));
    }
  else
    {
      printf ("INFO: %s results:\n", af_name);

      for (current = result; current != NULL && current->ai_canonname != NULL; current = current->ai_next)
        printf ("%s\n", current->ai_canonname);

      freeaddrinfo (result);
    }

  return;
}

int
main (int argc, char **argv)
{
  char *query;

  /* There must be an argument, which we assume is the FQDN.  */
  if (argc < 2)
    return EXIT_FAILURE;

  /* Copy FQDN, and tokenize it into name.  */
  query = argv[1];

  printf ("query=%s\n", query);

  test (query, AF_UNSPEC, "AF_UNSPEC");
  test (query, AF_INET, "AF_INET");
  test (query, AF_INET6, "AF_INET6");

  return EXIT_SUCCESS;
}
