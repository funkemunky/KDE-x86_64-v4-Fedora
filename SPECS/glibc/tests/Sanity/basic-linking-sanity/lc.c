#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(){
  char one[] = "Whatever!";
  char *two;
  FILE *fp = fopen("lc.out", "w");

  fprintf(fp, "Printf: %d\n", 10);
  fprintf(fp, "Whatever: %s, length %d\n", one, strlen(one));

  two = malloc(sizeof(char) * 20);
  memcpy(two, one, 3);
  two[3] = '\0';
  fprintf(fp, "Two: %s, length %d\n", two, strlen(two));

  fclose(fp);
  free(two);
  return 0;
}
