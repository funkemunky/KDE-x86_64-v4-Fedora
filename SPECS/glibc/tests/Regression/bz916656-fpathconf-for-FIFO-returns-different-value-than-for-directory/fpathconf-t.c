#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

int main(void) {

  int fd151, fd152, fd161, fd162;
  long p151, p152, p161, p162;

  const char f15[15] = "fpathconf-t.15";
  const char f16[15] = "fpathconf-t.16";
  const char dot[2] = ".";

  fd151 = open(f15, O_RDONLY|O_NONBLOCK);

  p151 = fpathconf(fd151, _PC_PIPE_BUF);
  p152 = pathconf(f15, _PC_PIPE_BUF);

  if(p151 != p152) {
    printf("test15 FAIL - fpathconf for '%s' (%ld)  does not equal pathconf for '%s' (%ld) \n", f15, p151, f15, p152);
  } else {
    printf("test15 PASS - fpathconf for '%s' (%ld)  equals pathconf for '%s' (%ld) \n", f15, p151, f15, p152);
  }
  
  fd161 = open(dot, O_RDONLY);
  fd162 = open(f16, O_RDONLY|O_NONBLOCK);

  p161 = fpathconf(fd161, _PC_PIPE_BUF);
  p162 = fpathconf(fd162, _PC_PIPE_BUF);

  if(p161 != p162) {
    printf("test16 FAIL - fpathconf for '%s' (%ld)  does not equal fpathconf for '%s' (%ld) \n", dot, p161, f16, p162);
  } else {
    printf("test16 PASS - fpathconf for '%s' (%ld)  equals fpathconf for '%s' (%ld) \n", dot, p161, f16, p162);
  }

  close(fd161);
  close(fd162);

  return 0;
}
