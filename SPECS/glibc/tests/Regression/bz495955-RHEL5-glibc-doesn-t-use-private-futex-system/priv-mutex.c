/******************************************************************************
 *
 *   Copyright © International Business Machines  Corp., 2009
 *
 *   This program is free software;  you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY;  without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
 *   the GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program;  if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 * NAME
 *      priv-mutex.c
 *
 * DESCRIPTION
 *      Test the shared and private settings of pthread mutexes.
 *
 * USAGE:
 *      priv-mutex [-p][-s]
 *
 * AUTHOR
 *      Darren Hart <dvhltc@us.ibm.com>
 *
 * HISTORY
 *      2009-Apr-9: Initial version by Darren Hart <dvhltc@us.ibm.com>
 *
 *****************************************************************************/

#define _GNU_SOURCE
#include <unistd.h>
#include <stdio.h>
#include <pthread.h>
#include <time.h>
#include <errno.h>

#define MUTEX_PSHARED_FLAG 128
#define MUTEX_PI_FLAG 32

pthread_mutex_t mutex;
pthread_barrier_t lock_barrier;
pthread_barrier_t unlock_barrier;

void usage(char *arg0)
{
	printf("usage: %s [-p][-s]\n");
	printf("-p:		use private mutexes\n");
	printf("-s:		use shared mutexes\n");
	printf("no args:	use system default\n");
}

void *lock_thread(void *arg)
{
	int ret;
	if (pthread_mutex_lock(&mutex))
	{
		perror("lock_thread failed to acquire the lock");
		return NULL;
	}
	/* Let the main thread know we took the lock. */
        ret = pthread_barrier_wait(&lock_barrier);
        if (ret && ret != PTHREAD_BARRIER_SERIAL_THREAD) {
		perror("pthread_barrier_wait failed");
		return NULL;
        }
	/* Wait for the main thread to timeout trying to get the lock. */
        ret = pthread_barrier_wait(&unlock_barrier);
        if (ret && ret != PTHREAD_BARRIER_SERIAL_THREAD) {
		perror("pthread_barrier_wait failed");
		return NULL;
        }
	if (pthread_mutex_unlock(&mutex))
	{
		perror("main failed to release the lock");
		return NULL;
	}
	pthread_exit(0);
}

int main(int argc, char *argv[])
{
	int opt, pshared, child_ret, set_pshared = 0, ret = 0;
	pthread_mutexattr_t attr;
	struct timespec timeout;
	pthread_t child;

	while ((opt = getopt(argc, argv, "ps")) != -1) {
		switch (opt) {
		case 'p':
			pshared = PTHREAD_PROCESS_PRIVATE;
			set_pshared = 1;
			break;
		case 's':
			pshared = PTHREAD_PROCESS_SHARED;
			set_pshared = 1;
			break;
		default:
			usage(argv[0]);
			return -1;
		}
	}

	/* Setup the mutex. */
	if (pthread_mutexattr_init(&attr)) {
		perror("pthread_mutexattr_init failed");
		return -1;
	}
	if (pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_INHERIT)) {
		perror("pthread_mutexattr_setprotocol failed");
		return -1;
	}
	if (set_pshared) {
		if (pthread_mutexattr_setpshared(&attr, pshared)) {
			perror("pthread_mutexattr_setpshared failed");
			return -1;
		}
	}
	if (pthread_mutex_init(&mutex, &attr)) {
		perror("pthread_mutex_init failed");
		return -1;
	}

	printf("Using %s mutexes\n", mutex.__data.__kind & MUTEX_PSHARED_FLAG ?
	       "PTHREAD_PROCESS_SHARED" : "PTHREAD_PROCESS_PRIVATE");


	/* Setup the barriers. */
	if (pthread_barrier_init(&lock_barrier, NULL, 2)) {
		perror("failed to create lock_barrier");
		return -1;
	}
	if (pthread_barrier_init(&unlock_barrier, NULL, 2)) {
		perror("failed to create lock_barrier");
		return -1;
	}

	/* 
	 * Spawn a thread to grab the lock and then try to grab it here,
	 * forcing glibc to make the appropriate futex system-call.
	 */
	if (pthread_create(&child, NULL, lock_thread, NULL)) {
		perror("failed to create child thread");
		return -1;
	}
        ret = pthread_barrier_wait(&lock_barrier);
        if (ret && ret != PTHREAD_BARRIER_SERIAL_THREAD) {
		perror("pthread_barrier_wait failed");
		return -1;
        }
	timeout.tv_sec = 0;
	timeout.tv_nsec = 100000;
        ret = pthread_mutex_timedlock(&mutex, &timeout);
        if (ret && ret != ETIMEDOUT) {
		perror("main failed to acquire the lock");
		return -1;
	}
        ret = pthread_barrier_wait(&unlock_barrier);
        if (ret && ret != PTHREAD_BARRIER_SERIAL_THREAD) {
		perror("pthread_barrier_wait failed");
		return -1;
        }
	pthread_join(child, NULL);


	/* Cleanup */
	if (pthread_mutex_destroy(&mutex)) {
		perror("pthread_mutex_destroy failed");
		ret = -1;
	}
	if (pthread_mutexattr_destroy(&attr)) {
		perror("pthread_mutexattr_destroy failed");
		ret = -1;
	}
	return ret;
}
