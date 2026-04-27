#include <stdio.h>
#include <stdlib.h>

#include <errno.h>
#include <grp.h>
#include <pthread.h>
#include <unistd.h>

pthread_cond_t cond1 = PTHREAD_COND_INITIALIZER, cond2 = PTHREAD_COND_INITIALIZER;
pthread_mutex_t mut1 = PTHREAD_MUTEX_INITIALIZER,  mut2 = PTHREAD_MUTEX_INITIALIZER;

void dump_ids(const char* head)
{
    gid_t groups[32];
    int ngroups, i;

    printf("%s: ", head);

    if ((ngroups = getgroups(sizeof(groups)/sizeof(groups[0]), groups)) < 0)
    {
    perror("getgroups");
    exit(1);
    }

    for (i = 0; i < ngroups; i++)
    printf("%d%s", groups[i], (i < ngroups - 1 ? ", " : ""));
    printf("\n\n");
}

void* body(void* arg)
{
    printf("Launched a new thread\n\n");

    pthread_mutex_lock(&mut1);
    pthread_mutex_lock(&mut2);

    pthread_cond_signal(&cond1);
    pthread_mutex_unlock(&mut1);

    pthread_cond_wait(&cond2, &mut2);
    pthread_mutex_unlock(&mut2);

    dump_ids("Launched thread groups");

    return NULL;
}

int main(void)
{
    pthread_t thread;
    int err;

    dump_ids("Initial groups");

    pthread_mutex_lock(&mut1);

    if ((err = pthread_create(&thread, NULL, &body, NULL)))
    {
    errno = err;
    perror("pthread_create");
    return 1;
    }

    pthread_cond_wait(&cond1, &mut1);
    pthread_mutex_unlock(&mut1);

    printf("Changing groups in the main thread...\n\n");
    {
    gid_t gid[] = { 20, 15 };

    if (setgroups(2, gid) < 0)
    {
        perror("setgroups");
        return 1;
    }
    }

    dump_ids("Main thread groups");

    pthread_mutex_lock(&mut2);
    pthread_cond_signal(&cond2);
    pthread_mutex_unlock(&mut2);

    pthread_join(thread, NULL);

    return 0;
}
