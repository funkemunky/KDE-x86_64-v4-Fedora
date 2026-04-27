#include <pthread.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>

static void *dummy_thread (void *arg) { printf ("started\n"); return arg; }

static int start (int policy, int priority)
{
  pthread_attr_t attr;
  struct sched_param param;
  pthread_t thread_id;
  int r;

  pthread_attr_init(&attr);
  pthread_attr_setschedpolicy (&attr, policy);
  param.sched_priority = priority;
  pthread_attr_setschedparam (&attr, &param);
  pthread_attr_setinheritsched (&attr, PTHREAD_EXPLICIT_SCHED);
  r = pthread_create(&thread_id, &attr, dummy_thread, NULL);
  pthread_attr_destroy(&attr);
  if (r == 0) { pthread_join(thread_id, NULL); }
  else { errno = r; perror ("pthread_create"); }
  return r;
}

int main(int argc, char **argv)
{
  if (argc > 1) {
    switch (atoi (argv[1])) {
    case 0: start (SCHED_OTHER, 0); break;
    case 1: start (SCHED_OTHER, 10); break;
    case 2: start (SCHED_FIFO, 0); break;
    case 3: start (SCHED_FIFO, 10); break;
    case 4: if (start (SCHED_FIFO, 10) != 0) start (SCHED_OTHER, 0); break;
    }
  }
  return 0;
}
