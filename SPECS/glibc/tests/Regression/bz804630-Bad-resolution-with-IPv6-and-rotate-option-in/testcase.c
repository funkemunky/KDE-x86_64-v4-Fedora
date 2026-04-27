/* taken from Bug 804630 */
#include <stdio.h>
#include <stdlib.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>

int main(void)
{
    struct addrinfo *result;
    struct addrinfo *res;
    int error;

    /* resolve the domain name into a list of addresses */
    error = getaddrinfo("tak.tik.com", NULL, NULL, &result);
    if (error != 0)
    {
        fprintf(stderr, "error in getaddrinfo: %s\n", gai_strerror(error));
        return EXIT_FAILURE;
    }
    else
    {
        printf("Test OK\n");
    }

    freeaddrinfo(result);
    return EXIT_SUCCESS;
}
