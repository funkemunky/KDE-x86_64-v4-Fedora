#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <pthread.h>

static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
static volatile int   counter = 0;
static volatile int   stop = 0;

static void *
testTimedLock(void *arg)
{
  int rc = 0;
  struct timespec abstime;
  abstime.tv_sec = time(0) + 10;
  abstime.tv_nsec = 100000000;

  for ( ; stop == 0; ) {
    rc = pthread_mutex_timedlock( &mutex, &abstime );
    if (rc != 0) { perror("Errno:"); };
    assert(rc == 0);
    ++counter;
    rc = pthread_mutex_unlock( &mutex );
    if (rc != 0) { perror("Errno:"); };
    assert(rc == 0);
  }
  return 0;
}

void
createThreads(int nThreads, pthread_t *thr)
{
  int nt;
  for ( nt = 0 ; nt < nThreads ; ++nt ) {
    int rc = pthread_create( thr+nt, NULL, testTimedLock, NULL);
    if (rc != 0) { perror("Errno:"); };
    assert( rc == 0 );
  }
}

void
joinThreads(int nThreads, pthread_t *thr)
{
  int nt;
  for ( nt = 0 ; nt < nThreads ; ++nt ) {
    int rc = pthread_join( thr[nt], NULL);
    if (rc != 0) { perror("Errno:"); };
    assert( rc == 0 );
  }
}

int
main(void)
{
  int nThreads = 10;
  pthread_t thr[nThreads];

  createThreads(nThreads, thr);
  usleep (1000000); // 1 second
  stop = 1;
  joinThreads(nThreads, thr);
  printf("counter = %d\n", counter);
  return 0;
}
