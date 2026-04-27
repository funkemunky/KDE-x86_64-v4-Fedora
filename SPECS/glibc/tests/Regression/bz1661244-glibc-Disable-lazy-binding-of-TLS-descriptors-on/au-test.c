#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

struct in_addr a;

int main(int argc, char *argv[])
{
   inet_ntoa(a);
   return 0;
}
