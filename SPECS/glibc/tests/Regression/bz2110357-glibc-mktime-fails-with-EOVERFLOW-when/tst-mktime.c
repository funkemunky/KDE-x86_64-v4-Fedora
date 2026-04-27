#include <time.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    time_t t;
    struct tm tm;

    setenv("TZ", "Asia/Tokyo", 1);

    memset(&tm, 0, sizeof(tm));
    tm.tm_mday = 1;
    tm.tm_mon = 1;
    tm.tm_year = 2023;
    tm.tm_isdst = 1;

    t = mktime(&tm);
    printf("mktime(&tm) = %d\n", t);
    if (t < 0)
        exit(1);

    return 0;
}
