/* taken from bz#639000 */

#include <stdio.h>
#include <locale.h>

int main()
{
    struct lconv *lv;
   
    setlocale (LC_ALL, "");
    lv = localeconv();
    fprintf (stdout, "Currency symbol for locale: %s\n", lv->currency_symbol);
    fprintf (stdout, "Intl currency sym for locale: %s\n", lv->int_curr_symbol);
    return 0;
}
