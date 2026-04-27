#include <stdio.h>
#include <unistd.h>

int main(void)
{
  setvbuf(stderr, NULL, _IOFBF, BUFSIZ);
  setvbuf(stdout, NULL, _IONBF, 0);

  fprintf(stderr, "stderr");
  fprintf(stdout, "stdout");
  sleep(1);
  printf("\n");


  return 0;
}
