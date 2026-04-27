#include <sys/types.h>
#include <errno.h>
#include <grp.h>
#include <nss.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

#define MODULE "db"
#define NUMTHREADS 512

static pthread_rwlock_t startlock, outlock;

static int
compare_gid(const void *a, const void *b)
{
	gid_t ga, gb;
	long la, lb;
	ga = *(gid_t *) a;
	gb = *(gid_t *) b;
	la = ga;
	lb = gb;
	return (int)(la - lb);
}

static void *
thread_main(void *arg)
{
	gid_t *groups;
	int result, n_groups, i;
	pthread_rwlock_rdlock(&startlock);

	n_groups = 32;
	groups = malloc(sizeof(groups[0]) * n_groups);

	if (groups != NULL) {
		do {
			result = getgrouplist((const char *)arg, 0,
					      groups, &n_groups);
			if ((result == -1) && (errno == ERANGE)) {
				n_groups += 2;
				free(groups);
				groups = malloc(sizeof(groups[0]) * n_groups);
			}
		} while ((result == -1) && (errno == ERANGE));
	}

	if (result >= 0) {
		qsort(groups, n_groups, sizeof(groups[0]), &compare_gid);
		pthread_rwlock_wrlock(&outlock);
		for (i = 0; i < n_groups; i++) {
			if (i > 0) {
				printf(":");
			}
			printf("%lu", (unsigned long)groups[i]);
		}
		printf("\n");
		pthread_rwlock_unlock(&outlock);
	} else {
		result = errno;
		pthread_rwlock_wrlock(&outlock);
		printf("%s: %s\n", (const char *)arg, strerror(result));
		pthread_rwlock_unlock(&outlock);
	}
	return NULL;
}

int
main(int argc, char **argv)
{
	unsigned int i, j;
	char *guser;
	pthread_t tids[NUMTHREADS];

	__nss_configure_lookup("group", MODULE);

	guser = argc > 1 ? argv[1] : "root";

	if (pthread_rwlock_init(&startlock, NULL) != 0) {
		fprintf(stderr, "pthread_rwlock_init: %s\n", strerror(errno));
		return 1;
	}
	pthread_rwlock_wrlock(&startlock);
	if (pthread_rwlock_init(&outlock, NULL) != 0) {
		fprintf(stderr, "pthread_rwlock_init: %s\n", strerror(errno));
		return 1;
	}

	for (i = 0; i < sizeof(tids) / sizeof(tids[0]); i++) {
		if (pthread_create(&tids[i], NULL, &thread_main, guser) != 0) {
			break;
		}
	}
	if (i < sizeof(tids) / sizeof(tids[0])) {
		fprintf(stderr, "error starting thread #%d, continuing\n", i);
	}

	pthread_rwlock_unlock(&startlock);

	for (j = 0; j < i; j++) {
		pthread_join(tids[j], NULL);
	}

	return 0;
}
