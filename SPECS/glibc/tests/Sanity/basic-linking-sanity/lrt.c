#include <stdio.h>
#include <sys/mman.h>
#include <fcntl.h>

int main(){
  FILE *fp = fopen("lrt.out", "w");

  int opn = shm_open("/stuffz0r", O_RDWR|O_CREAT, 0777);
  if ( opn == -1 )
    fprintf(fp, "shm_open failed\n");
  else
    fprintf(fp, "shm_open successful\n");

  int unl = shm_unlink("/stuffz0r");
  if ( unl == -1 )
    fprintf(fp, "shm_unlink failed\n");
  else
    fprintf(fp, "shm_unlink successful\n");

  fclose(fp);
  return 0;
}
