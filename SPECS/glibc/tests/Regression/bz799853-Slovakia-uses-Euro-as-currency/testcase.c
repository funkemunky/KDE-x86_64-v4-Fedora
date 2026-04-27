#include <stdio.h>
#include <locale.h>
int main()
{
    if( setlocale(LC_MONETARY, "") == NULL ) {
        puts("Cannot set locale");
        return 1;
    } else {
       struct lconv *l = localeconv();
       printf("Local currency symbol: %s\n", l->currency_symbol);
       printf("International currency symbol: %s\n", l->int_curr_symbol);
    }

    return 0;
}
