
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <string.h>
#include <errno.h>

int main(int argc, char **argv)
{
	struct sockaddr_in6 addr6;
	socklen_t size = sizeof(addr6);
	int ret;

	memset(&addr6, 0, size);
	addr6.sin6_family = AF_INET6;
	addr6.sin6_port = 0;
	addr6.sin6_addr = in6addr_loopback;

	printf("==Both nodename and servname are null if the NI_NAMEREQD flag is set==\n");
	ret = getnameinfo((struct sockaddr *) &addr6, size, NULL, 0, NULL, 0, NI_NAMEREQD);
	if(ret != EAI_NONAME)
	{
		printf("ERROR:return %d, expect error EAI_NONAME\n", ret);
		printf("<=== NG ===>\n");
		exit(1);
	}
	
	printf("<=== OK ===>\n");

	return 0;
}
