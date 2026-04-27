#include <sys/types.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/mman.h>
#include <strings.h>
#include <iostream>
#include <unistd.h>
#include <signal.h>

using namespace std;

int main(int argc, char **argv)
{
 ::signal(SIGXFSZ, SIG_IGN);

 if (argc!=3) 
 {
   puts("usage: posixFallocateTester <filename> <size in bytes>");
   return 1;
 }

 const size_t N = ::atoi(argv[2]);

 
 int fd = open(argv[1], O_RDWR| O_CREAT |O_TRUNC, 0666 );

 if (fd < 0)
 { 
   perror("open failed");
   exit(1);
 }


 if (::posix_fallocate(fd, 0, N) != 0)
 { 
   perror("posix_fallocate failed");
   exit(1);
 }
  
}