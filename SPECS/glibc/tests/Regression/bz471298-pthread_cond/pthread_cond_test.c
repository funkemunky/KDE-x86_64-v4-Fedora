#include <pthread.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <errno.h>
#include <signal.h>
#include <string.h>
#include <time.h>
#include <sys/mman.h>
#include <sys/wait.h>

#define PTHREAD_MUTEX_DEFAULT 0
#define PTS_FAIL        1

/* The shared data */
typedef struct
{
	int	     	count;     /* number of children currently waiting */
	pthread_cond_t  cnd;
	pthread_mutex_t mtx;
	int	     	predicate; /* Boolean associated to the condvar */
	clockid_t       cid;       /* clock used in the condvar */
	char	    	fork;      /* the children are processes */
} testdata_t;

testdata_t * td;

int child(int arg);

int main (int argc, char * argv[])
{
	int ret;

	pthread_mutexattr_t ma;
	pthread_condattr_t ca;

	pid_t pid, p_child;
	int ch;
	int status;

	pthread_t t_timer;

	char filename[] = "/tmp/cond_wait_stress-XXXXXX";
	size_t sz, ps;
	void * mmaped;
	int fd;
	char * tmp;

	fd = mkstemp(filename);
	if (fd < 0) {
		perror("mkstemp");
		exit(EXIT_FAILURE);
	}
	unlink(filename);

	ps  = (size_t)sysconf(_SC_PAGESIZE);
	sz  = ((sizeof(testdata_t) / ps) + 1) * ps; /* # pages needed to store the testdata */
	tmp = calloc( 1 , sz);

	if (tmp == NULL) {
		perror("calloc");
		exit(EXIT_FAILURE);
	}

	if (write (fd, tmp, sz) != (ssize_t) sz) {
		perror("write");
		exit(EXIT_FAILURE);
	}

	mmaped = mmap(NULL, sz, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (mmaped == MAP_FAILED) {
		perror("mmap"); 
		exit(EXIT_FAILURE); 
	}
	td = (testdata_t *) mmaped;
	memset(td, 0, sizeof(testdata_t));
	free(tmp);

	/* mutexattr & condattr init */	
	ret = pthread_mutexattr_init(&ma);
	if (ret != 0) {
		perror("pthread_mutexattr_init");
		exit(EXIT_FAILURE);
	}
	ret = pthread_condattr_init(&ca);
	if (ret != 0) {
		perror("pthread_condattr_init");
		exit(EXIT_FAILURE);
	}


	ret = pthread_mutexattr_settype(&ma, PTHREAD_MUTEX_DEFAULT);
	if (ret != 0) {
		perror("pthread_mutexattr_settype");
		exit(EXIT_FAILURE);
	}

	/* Set "PTHREAD_PROCESS_SHARED"  */
	ret = pthread_mutexattr_setpshared(&ma, PTHREAD_PROCESS_SHARED);
	if(ret != 0) {
		perror("pthread_mutexattr_setpshared");
		exit(EXIT_FAILURE);
	}
	ret = pthread_condattr_setpshared(&ca, PTHREAD_PROCESS_SHARED);
	if(ret != 0) {
		perror("pthread_condattr_setpshared");
		exit(EXIT_FAILURE);
	}


	/* Set "CLOCK_MONOTONIC" */
	ret = pthread_condattr_setclock(&ca, CLOCK_MONOTONIC);
	if(ret != 0) {
		perror("pthread_condattr_setclock");
		exit(EXIT_FAILURE);
	}
	ret = pthread_condattr_getclock(&ca, &td->cid);
	if(ret != 0) {
		perror("pthread_condattr_getclock");
		exit(EXIT_FAILURE);
	}


	ret = pthread_cond_init(&td->cnd, &ca);
	if(ret != 0) {
		perror("pthread_cond_init");
		exit(EXIT_FAILURE);
	}
	ret = pthread_mutex_init(&td->mtx, &ma);
	if(ret != 0) {
		perror("pthread_mutex_init");
		exit(EXIT_FAILURE);
	}

	ret = pthread_condattr_destroy(&ca);
	if (ret != 0) { 
		perror("pthread_condattr_destroy");
		exit(EXIT_FAILURE);
	}
	ret = pthread_mutexattr_destroy(&ma);
	if (ret != 0) {
		perror("pthread_condattr_destroy");
		exit(EXIT_FAILURE);
	}

	td->fork = 1;
	p_child  = fork();
	if (p_child < 0) {
		perror("fork");
		exit(EXIT_FAILURE);
	}

	if (p_child == 0) {
		/* child process */
		child(0);
		exit(EXIT_SUCCESS);
	}


	/* Parent process */

	ret = pthread_mutex_lock(&td->mtx);
	if (ret != 0)  {
		perror("pthread_mutex_lock");
		exit(EXIT_FAILURE);
	}

	ch = td->count;

	ret = pthread_mutex_unlock(&td->mtx);
	if (ret != 0)  {
		perror("pthread_mutex_unlock");
		exit(EXIT_FAILURE);
	}

	sleep(5);

	ret = pthread_mutex_lock(&td->mtx);
	if (ret != 0) {
		perror("pthread_mutex_lock");
		exit(EXIT_FAILURE);
	}

	td->predicate=1;
	ret = pthread_cond_signal(&td->cnd);
	printf("parent: pthread_cond_signal\n");
	if (ret != 0) {
		perror("pthread_cond_signal");
		exit(EXIT_FAILURE);
	}

	ret = pthread_mutex_unlock(&td->mtx);
	if (ret != 0) {
		perror("pthread_mutex_unlock");
		exit(EXIT_FAILURE);
	}

	pid = waitpid(p_child, &status, 0);
	if(pid != p_child) {
		perror("waitpid");
		exit(EXIT_FAILURE);
	}

	ret = pthread_cond_destroy(&td->cnd);
	if (ret != 0) {
		perror("pthread_cond_destroy");
		exit(EXIT_FAILURE);
	}
	ret = pthread_mutex_destroy(&td->mtx);
	if (ret != 0) {
		perror("pthread_mutex_destroy");
		exit(EXIT_FAILURE);
	}

	return 0;
}

int child(int arg)
{
	int ret=0;
	struct timespec ts;

	/* lock the mutex */
	ret = pthread_mutex_lock(&td->mtx);

	printf("child: pthread_cond_wait\n");

	do {
	/* Wait while the predicate is false */
		ret = pthread_cond_wait(&td->cnd, &td->mtx);
	} while ((ret == 0) && (td->predicate==0));


	ret = pthread_cond_signal(&td->cnd);
	ret = pthread_mutex_unlock(&td->mtx);

	return 0;
}
