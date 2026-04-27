/*
 * bz#656530
 * Fix comparison in sqrtl for IBM long double 128
 * http://sourceware.org/ml/libc-alpha/2010-11/msg00033.html
 */
#include <math.h>
#include <stdio.h>

int main()
{
	long double x, y, sum, root;

	x = 0x1.c30000000029p-175;
	y = 0x1.49p+504;

	sum = x*x + y*y;
	root = sqrtl(sum);

	printf("%a\n", (double)root);
	/* should produce 0x1.49p+504 and not -inf */

	return 0;
}

