#include <stdlib.h>
#include <unistd.h>

int main(void)
{
  unsigned int i;
#pragma omp parallel num_threads(256) private(i)
  {
    i = 1;
    while (i != 2000) {
      void *ptr = malloc(rand() % 65536);
      usleep((rand() % 100) * 100);
      free(ptr);
      usleep((rand() % 100) * 100);
      i++;
    }
  #pragma omp barrier
  }
  return 0;
}
