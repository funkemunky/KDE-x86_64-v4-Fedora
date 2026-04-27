#include <stdio.h>
#include <stdlib.h>
#include <semaphore.h>
#include <pthread.h>
#include <time.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>

void func(sem_t *semp)
{
	struct timespec ts;

	sleep(2);
	ts.tv_sec = 0;
	ts.tv_nsec = -1;

	errno = 0;
	printf("thread: calling sem_timedwait with bogus tv_nsec\n");
	if (sem_timedwait(semp, &ts) != 0)
		printf("thread: sem_timedwait: errno = %d strerror = %s\n",
		       errno, strerror(errno));

	printf("thread: calling sem_post\n");
	if (sem_post(semp) != 0)
		printf("thread: sem_post: errno = %d strerror = %s\n", errno,
		       strerror(errno));
}

int main()
{
	struct timespec ts;
	pthread_t thread;
	sem_t sem;
	int i = 0, sval = 0;

	sem_init(&sem, 0, 0);

	pthread_create(&thread, NULL, (void *)&func, (void *)&sem);

	/* two passes to illustrate that only the processes that are already
	   waiting for the semaphore when the call to sem_timedwait with the
	   bogus args is made are negatively impacted, i.e. subsequent calls
	   to sem_timedwait succeed */
	for (i = 0; i < 2; i++) {
		sem_getvalue(&sem, &sval);
		printf("main: top of loop: sval = %d\n", sval);

		clock_gettime(CLOCK_REALTIME, &ts);
		ts.tv_sec += 10;
		ts.tv_nsec = 0;

		printf("main: calling sem_timedwait\n");
		if (sem_timedwait(&sem, &ts) != 0) {
			printf("main: sem_timedwait: errno = %d strerror = "
			       "%s\n", errno, strerror(errno));
		} else {
			printf("main: sem_timedwait: success\n");
			printf("main: calling sem_post\n");
			if (sem_post(&sem) != 0)
				printf("thread: sem_post: errno = %d strerror "
				      "= %s\n", errno, strerror(errno));
		}
	}
}
