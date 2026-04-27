#include <string.h>
#include <errno.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
	FILE* f;

	if (argc != 3) return 1;

	f = fopen (argv[1], argv[2]);
	if (f == NULL) {
		return 1;
	}
	if (fclose (f)) {
                return 1;
        }

	return 0;
}

