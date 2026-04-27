#include <pthread.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>

#define	LOOPS	1000

uid_t	uid;

void *subthread(void *dummy)
{
	setuid(uid);
}

int main(void)
{
	pthread_t tid[LOOPS];
	int	i, ret;

	uid = getuid();

	for(i=0; i < LOOPS; i++) {
		ret = pthread_create(&tid[i], NULL, &subthread, NULL);
		if(ret != 0) {
			perror("pthread_create");
			return 1;
		}
	}
	for(i=0; i < LOOPS; i++) {
		ret = pthread_join(tid[i], NULL);
		if(ret != 0) {
			perror("pthread_join");
		}
	}
	return 0;
}

