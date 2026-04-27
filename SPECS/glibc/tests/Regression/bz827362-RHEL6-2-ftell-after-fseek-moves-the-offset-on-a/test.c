#include <stdio.h>
#include <stdlib.h>
#include <locale.h>
#include <wchar.h>

int main(int argc, char** argv)
{
	FILE *fp;

#ifdef UTF8
	setlocale(LC_ALL, "en_US.utf8");
#else
	setlocale(LC_ALL, "en_US");
#endif
	fp = fopen("output.txt", "w+");
	if (fp == NULL) {
		perror("fopen");
		exit(1);
	}
	if (fputws(L"abc\n", fp) == -1) {
		perror("fputws");
		exit(1);
	}
	printf("before=%d\n", ftell(fp));
	if (fseek(fp, 0L, SEEK_END) == -1) {
		perror("fseek");
		exit(1);
	}
	printf("fseek=%d\n", ftell(fp));
	if (fputws(L"xyz\n", fp) == -1) {
		perror("fputws");
		exit(1);
	}
	printf("after=%d\n", ftell(fp));
	fclose(fp);
	return 0;
}
