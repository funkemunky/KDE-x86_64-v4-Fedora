
#include	<stdio.h>
#include	<string.h>
#include	<errno.h>
#include	<semaphore.h>

/* Semaphore variable structure.  */
// taken from nptl/sysdeps/unix/sysv/linux/internaltypes.h
struct new_sem
{
	unsigned int		value;
	int			private;
	unsigned long int	nwaiters;
};

int main(void)
{
	struct timespec ts = {0, -1};	// set incorrect nanoseconds
	sem_t		sem;
	int		ret = 0;
	struct new_sem  *isem = (struct new_sem *)&sem;

	sem_init(&sem, 0, 0);

	printf("before sem_timedwait(): new_sem->nwaiters = 0x%x\n", isem->nwaiters);
	if (sem_timedwait(&sem, &ts) < 0)
		printf("ERR: sem_timedwait() failed (errno=%d: %s)\n", errno, strerror(errno));
	printf("after sem_timedwait(): new_sem->nwaiters = 0x%x\n", isem->nwaiters);

	return (isem->nwaiters != 0);
}

