#include <stdio.h>

#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <string.h>
#include <strings.h>
#include <stdlib.h>
#include <ctype.h>

void
dump_res (struct addrinfo *p_res)
{
  struct addrinfo *iter = p_res;
  while (iter != 0)
    {
      struct sockaddr_in *addr1b;
      addr1b = (struct sockaddr_in *) iter->ai_addr;
      printf ("getaddrinfo returns: %s %d %d\n", inet_ntoa (addr1b->sin_addr),
       iter->ai_family, iter->ai_protocol);
      iter = iter->ai_next;
    }
}

int
main (int argc, char *argv[])
{
  if (argc != 2)
    {
      printf ("Usage prog hostname\n");
      exit (7);
    }

  struct addrinfo hints, *res;
  int error, i;

  bzero (&hints, sizeof (hints));
  hints.ai_flags = AI_CANONNAME;
  hints.ai_family = AF_UNSPEC;

  for (i = 0; i < 2; i++)
    {
      printf ("======== ATTEMPT %d ===============\n", i);

      if ((error = getaddrinfo (argv[1], NULL, &hints, &res)))
        {
          perror ("getaddrinfo");
          exit (-1);
        }

      dump_res (res);
      freeaddrinfo (res);
   }
   /* not such a bad idea ;-) */
   return 0;
}
