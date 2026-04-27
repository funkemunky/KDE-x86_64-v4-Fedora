#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string.h>

#define LEN	16
#define OPT_LEN(len)	((len - 8) >> 3)

int main(int argc, char **argv) {
	char extbuf[LEN], cbuf[LEN];
	int extlen;
	uint8_t *len;

	memset(extbuf, 0, sizeof(extbuf));
	memset(cbuf, 0, sizeof(cbuf));
	len = (uint8_t *)(extbuf + 1);

	printf("== calculate the needed buffer size if extlen is: %d ==\n",LEN);
	extlen = inet6_opt_init(extbuf, LEN);
	if (extlen != 2) {
		printf("ERROR: return invalid length %d, expect:2 \n", extlen);
		printf("<=====NG=====>\n");
		exit(1);
	}

	if (*len != OPT_LEN(LEN)) {
		printf("ERROR: the length field of extension header is invalid, length %d, expect:%d \n", 
			*len, OPT_LEN(LEN));
		printf("<=====NG=====>\n");
		exit(1);
	}

	printf("OK\n");
	return 0;
}
