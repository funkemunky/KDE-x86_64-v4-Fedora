#include <stdio.h>
#include <math.h>

int main(){
  FILE *fp = fopen("lm.out", "w");
  double a = pow(10, 2);
  fprintf(fp, "POW: %0.2f\n", a);
  fprintf(fp, "SIN: %0.2f\n", 1.0);


  fclose(fp);
  return 0;
}
