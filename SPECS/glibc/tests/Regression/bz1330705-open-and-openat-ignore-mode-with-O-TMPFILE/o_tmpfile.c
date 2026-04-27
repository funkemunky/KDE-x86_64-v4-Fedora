#define _GNU_SOURCE
#include <linux/limits.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/syscall.h>

/* from /usr/include/bits/fcntl-linux.h in newer glibc */
#ifndef __O_TMPFILE
#pragma message "__O_TMPFILE is not defined!"
# define __O_TMPFILE   (020000000 | __O_DIRECTORY)
//# define O_TMPFILE      __O_TMPFILE     /* Atomically create nameless file.  */
#endif

int main()
{
    int fd, kfd;
    char path[PATH_MAX], tmp[PATH_MAX];
    struct stat statbuf;

    kfd = syscall(SYS_openat, AT_FDCWD, ".", __O_TMPFILE | O_RDWR, 0600);
    if (kfd == -1) {
        if (errno == EISDIR || errno == ENOTSUP) {
            printf("__O_TMPFILE not supported by kernel, next checks dont make sense!\n");
            exit(10);
        }
    }

    fd = openat(AT_FDCWD, ".", __O_TMPFILE | O_RDWR, 0600);
    if (fd == -1) {
        if (errno == EISDIR || errno == ENOTSUP) {
            printf("__O_TMPFILE not supported by glibc\n");
            exit(EXIT_FAILURE);
        }
    }

    snprintf(path, PATH_MAX,  "/proc/self/fd/%d", fd);
    readlink(path, tmp, PATH_MAX);
    printf("%s -> %s file created with __O_TMPFILE\n", path, tmp);

    if (stat(path, &statbuf) == -1) {
        perror("stat");
        exit(EXIT_FAILURE);
    }

    printf("%s has mode 0%o\n", path, statbuf.st_mode & ~S_IFMT);

    if ((statbuf.st_mode & ~S_IFMT) != 0600) {
        printf("FAIL: mode is not 0600\n");
        exit(EXIT_FAILURE);
    }

    return 0;
}
