#include "stdio.h"
#include <locale.h>
#include <monetary.h>
#define MAX_OUT 10
int main (){
	ssize_t out_size;
	char out[MAX_OUT];
	if(setlocale(LC_ALL, "pt_PT.utf8") == NULL ) {
		puts("Cannot set locale");
		return 1;
	} else {
		out_size = strfmon(out,MAX_OUT, "%n", 5.95);
		if (out_size == -1 ) return 2;
		printf("%s\n",out);
		out_size = strfmon(out,MAX_OUT, "%!n", 5.95);
		if (out_size == -1 ) return 2;
		printf("%s\n",out);
		return 0;
	}
}
