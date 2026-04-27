#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>


static int* internal_lock = NULL;


static void cuda_hook_init ()
{
printf("%s:%d\n",__func__,__LINE__);
  if(internal_lock == NULL)
  {
printf("%s:%d\n",__func__,__LINE__);
  }
}

