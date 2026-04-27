
#include	<stdio.h>
#include	<string.h>
#include	<errno.h>
#include	<semaphore.h>

#include <pthread.h>
#include <unistd.h>

//#define TST_TEST_MODE 1

#define __HAVE_64B_ATOMICS 1

/* Semaphore variable structure.  */
// taken from nptl/sysdeps/unix/sysv/linux/internaltypes.h
struct new_sem
{
#if __HAVE_64B_ATOMICS
  /* The data field holds both value (in the least-significant 32 bytes) and
     nwaiters.  */
# if __BYTE_ORDER == __LITTLE_ENDIAN
#  define SEM_VALUE_OFFSET 0
# elif __BYTE_ORDER == __BIG_ENDIAN
#  define SEM_VALUE_OFFSET 1
# else
# error Unsupported byte order.
# endif
# define SEM_NWAITERS_SHIFT 32
# define SEM_VALUE_MASK (~(unsigned int)0)
  unsigned long int data;
  int private;
  int pad;
#else
# define SEM_VALUE_SHIFT 1
# define SEM_NWAITERS_MASK ((unsigned int)1)
  unsigned int value;
  int private;
  int pad;
  unsigned int nwaiters;
#endif
};

#if TST_TEST_MODE
void func(sem_t *semp) {
	struct timespec ts1 = {10, 1};
	struct timespec ts2 = {10, 1};
	struct timespec ts3 = {10, 1};

	printf("Starting thread\n");

	if (sem_post(semp)  == -1) {
		printf("sem_post error\n");
		sem_timedwait(semp, &ts1);
	}

	if (sem_post(semp)  == -1) {
		printf("sem_post error\n");
		sem_timedwait(semp, &ts2);
	}
	if (sem_timedwait(semp, &ts3) < 0)
		printf("THREAD ERR: sem_timedwait() failed (errno=%d: %s)\n", errno, strerror(errno));

	sleep(10);
	printf("Finishing thread\n");
}
#endif


int main(void)
{
#if TST_TEST_MODE
	pthread_t thread1,thread2,thread3;
	struct timespec ts = {10, 1};	// set incorrect nanoseconds
#else
	struct timespec ts = {0, -1};	// set incorrect nanoseconds
#endif
	sem_t		sem;
	struct new_sem  *isem = (struct new_sem *)&sem;

	sem_init(&sem, 0, 0);

#if TST_TEST_MODE

	pthread_create(&thread1, NULL, (void *)&func, (void *)&sem);
	sleep(1);
	pthread_create(&thread2, NULL, (void *)&func, (void *)&sem);
	sleep(1);
	pthread_create(&thread3, NULL, (void *)&func, (void *)&sem);
	sleep(1);
#endif
	unsigned int *pres;
	pres=(unsigned int*) &isem->data;
	printf("before sem_timedwait(): new_sem->nwaiters = 0x%x\n", *pres );
	if (sem_timedwait(&sem, &ts) < 0)
		printf("ERR: sem_timedwait() failed (errno=%d: %s)\n", errno, strerror(errno));
        pres=(unsigned int*) &isem->data;
	printf("after sem_timedwait(): new_sem->nwaiters = 0x%x\n", *pres );
	return 0;
}

