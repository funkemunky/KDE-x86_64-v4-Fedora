#include <aio.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

__thread int x[4096];

struct aiocb * do_aio_write(int fd, char *buf, int len, int offset)
{

	struct aiocb *op = calloc(1, sizeof(struct aiocb));

	if (!op) {
		printf("Could not allocate memory\n");
		exit(1);
	}

	op->aio_fildes = fd;
	op->aio_buf = buf;
	op->aio_nbytes = len;
	op->aio_offset = offset;

	if (aio_write(op) == -1)
		printf("aio_write() err\n");
	else
		printf("aio_write() success\n");

	return op;
}

int main()
{
	char buf1[] = "Hello World\n";
	char buf2[] = "Goodbye World\n";
	int fd;
	struct aiocb *op1, *op2;

	fd = open("foo.txt", O_CREAT | O_WRONLY | O_TRUNC);

	if (fd == -1) {
		perror("open");
		exit(1);
	}

	op1 = do_aio_write(fd, buf1, strlen(buf1), 0);
	op2 = do_aio_write(fd, buf2, strlen(buf2), strlen(buf1));

	close(fd);
	return 0;
}
