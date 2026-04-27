#include <stdio.h>
#include <locale.h>
int
main(void)
{
    char *s;
    printf("%s\n", setlocale(LC_CTYPE, "tr_TR"));
    // printf("%s\n", setlocale(LC_CTYPE, "tr_TR.ISO8859-9"));
    printf("%s\n", setlocale(LC_CTYPE, NULL));
    s = setlocale(LC_CTYPE, "tr_TR.ISO8859-9");
    printf("%s\n", s ? s : "null");
    return 0;
}
