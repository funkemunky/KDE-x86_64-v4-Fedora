#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#define BUFSIZE 1024
int main(int argc, char *argv[]) {
	int r=0,i,attempts=0;
	char *buf=NULL;

	buf = malloc(BUFSIZE);
	switch (argc) {
		case 1:
			printf("Usage: %s count_of_attempts\n", argv[0]);
			break;
		case 2:
			attempts=atoi(argv[1]);
			printf("Running %s %d\n", argv[0], attempts);
			break;
		default:
			printf("Usage: \n");
			break;
	}

	for (i=0; i<attempts;i++) {
	       	r = getlogin_r(buf, (size_t)BUFSIZE);
		if(r!=0) {
			perror("getlogin_r error: ");
			printf("\n");
			exit(1);
		}
	//	printf("getlogin_r: %s;", buf);
	}
	printf("\n");

	return 0;
}
