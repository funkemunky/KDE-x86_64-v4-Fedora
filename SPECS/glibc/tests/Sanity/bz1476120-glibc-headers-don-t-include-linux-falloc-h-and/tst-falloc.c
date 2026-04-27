#define _GNU_SOURCE
#include <fcntl.h>
int test(int fd)
{
	return fallocate(fd, FALLOC_FL_PUNCH_HOLE | FALLOC_FL_KEEP_SIZE,
	 0, 1024 * 1024);
}
