#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <errno.h>
#include <sys/time.h>

pthread_rwlock_t rwlock;

#define TIMEVAL_TO_TIMESPEC(tv, ts) {		\
	(ts)->tv_sec  = (tv)->tv_sec;		\
	(ts)->tv_nsec = (tv)->tv_usec * 1000;	\
}

void * func(void *ignored)
{
	int ret = 0;
	struct timeval  tv;
	struct timespec ts;

	(void)gettimeofday(&tv, NULL);
	TIMEVAL_TO_TIMESPEC(&tv, &ts);

	ts.tv_sec = -1;

	ret = pthread_rwlock_timedwrlock(&rwlock, &ts);
	if (ret == ETIMEDOUT) {
		printf("pthread_rwlock_timedwrlock:TIME OUT.\n");
		pthread_exit(0);
	} else if (ret == EINVAL) {
		printf("pthread_rwlock_timedwrlock:INVALID ARG.\n");
		pthread_exit(0);
	}
	printf("pthread_rwlock_timedwrlock:return = %d\n", ret);
	pthread_exit(0);
}

int main(int argv, char *argc[])
{
	pthread_t tid;

	if (pthread_rwlock_init(&rwlock, NULL) != 0) {
		printf("pthread_rwlock_init error\n");
		exit(-1);
	}
	pthread_rwlock_wrlock(&rwlock);
	pthread_create(&tid, NULL, func, NULL);
	pthread_join(tid, NULL);

	return 0;
}
