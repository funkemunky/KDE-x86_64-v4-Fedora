#define _GNU_SOURCE
#include <stdio.h>
#include <sched.h>

int
main (void)
{
  printf ("%d\n", sched_getcpu ());
}
