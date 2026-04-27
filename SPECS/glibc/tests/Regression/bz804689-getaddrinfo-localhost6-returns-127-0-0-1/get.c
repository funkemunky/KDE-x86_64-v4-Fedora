/* from Jan Safranek  */

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>

#define BUF_SIZE 500

int
main(int argc, char *argv[])
{
   struct addrinfo hints;
   struct addrinfo *result, *rp;
   int s;
   char buf[BUF_SIZE];

   if (argc != 2) {
       fprintf(stderr, "Usage: %s host\n", argv[0]);
       exit(EXIT_FAILURE);
   }

   memset(&hints, 0, sizeof(struct addrinfo));
   hints.ai_family = PF_INET6;
   hints.ai_socktype = SOCK_DGRAM;
   hints.ai_flags = 0;
   hints.ai_protocol = 0;

   s = getaddrinfo(argv[1], NULL, &hints, &result);
   if (s != 0) {
       fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(s));
       exit(EXIT_FAILURE);
   }

   for (rp = result; rp != NULL; rp = rp->ai_next) {
	   if (rp->ai_family == PF_INET6)
		   inet_ntop(PF_INET6, &((struct sockaddr_in6 *) rp->ai_addr)->sin6_addr, buf, BUF_SIZE);
           else
		   inet_ntop(PF_INET, &((struct sockaddr_in *) rp->ai_addr)->sin_addr, buf, BUF_SIZE);
	   printf("Address: %s\n", buf);
   }
   return 0;
}
