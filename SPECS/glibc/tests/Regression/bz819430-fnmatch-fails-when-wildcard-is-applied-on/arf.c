/* taken from bugzilla and modified */

#include <fnmatch.h>
#include <locale.h>

int main()
{
    int flags = 0;
    char *pattern = "*.csv";
    char *string = "\366.csv";
    setlocale (LC_ALL, "en_US.UTF-8");
    return fnmatch (pattern, string, flags);
}
