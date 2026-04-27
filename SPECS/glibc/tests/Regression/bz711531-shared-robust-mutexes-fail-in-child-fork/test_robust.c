/* gcc -g2 -O0 -Werror -pthread -D_GNU_SOURCE test_robust.c -o test_robust */

#include <sys/fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <pthread.h>
#include <sys/mman.h>
#include <errno.h>
#include <stdio.h>
#include <linux/futex.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/wait.h>

static int level;
static int set_list;
static int verbose;

struct lock {
    pthread_mutex_t mutex;
};

#define LOCKFN "/tmp/test_robust.shm"
#define MAP_SIZE 4096

static void
show_robust_list ()
{
    struct robust_list_head* h;
    size_t hlen;

    if (!verbose) return;
    syscall(SYS_get_robust_list,0,&h,&hlen);
    if (h) {
	printf("%*c robust pid=%d self=%lx &head=%p head=%p offset=%ld pending=%p\n",
	       level,' ',getpid(),pthread_self(),h,h->list,h->futex_offset,h->list_op_pending);
    } else {
	printf("%*c robust list not set\n",level,' ');
    }
}


static void
where (const char* what, int incr)
{
    if (!verbose) return;
    if (incr < 0) {
	show_robust_list();
	level += incr;
    }
    printf("%*c%s pid=%d self=%lx\n",level+1,' ',what,getpid(),pthread_self());
    if (incr > 0) {
	level += incr;
	show_robust_list();
    }
}

struct lock*
map (int create)
{
    int fd;
    struct lock* lp;

    fd = open(LOCKFN,O_RDWR|(create ? O_CREAT : 0),0666);
    if (fd < 0) {
	perror(LOCKFN);
	exit(2);
    }
    if (create) {
	ftruncate(fd,MAP_SIZE);
    }
    lp = (struct lock*)mmap(0,MAP_SIZE,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
    if (lp == MAP_FAILED) {
	perror("mmap");
	exit(2);
    }
    if (create) {
	int err;
	pthread_mutexattr_t attr;

	pthread_mutexattr_init(&attr);
	pthread_mutexattr_setpshared(&attr,PTHREAD_PROCESS_SHARED);
	pthread_mutexattr_settype(&attr,PTHREAD_MUTEX_ERRORCHECK);
	pthread_mutexattr_setrobust(&attr,PTHREAD_MUTEX_ROBUST_NP);
	pthread_mutex_init(&lp->mutex,&attr);
	pthread_mutexattr_destroy(&attr);

	munmap(map,MAP_SIZE);
	close(fd);
	lp = NULL;
    }
    return lp;
}


static void*
test (void* arg)
{
    struct lock* lp;
    int err;

    where("test start",1);

    lp = map(0);
    err = pthread_mutex_lock(&lp->mutex);
    if (err) {
	if (err == EOWNERDEAD) {
	    printf("    claimed lock from dead owner\n");
	    pthread_mutex_consistent(&lp->mutex);
	} else {
	    perror("pthread_mutex_lock");	    
	    return NULL;
	}
    }

    where("test end",-1);
}


static void*
run_thread (void* arg)
{
    where("thread start",1);
    test(arg);
    where("thread end",-1);
}


static void
task (int thread)
{
    where("fork start",1);
    if (thread) {
	pthread_t t;
	void* res;

	pthread_create(&t,NULL,run_thread,NULL);
	pthread_join(t,&res);
    } else {
	test(NULL);
    }
    where("fork end",-1);
}

static void
run_tasks (int ntasks, int thread, int set)
{
    int status;
    int i;

    set_list = set;
    where("run start",1);
    for (i = 0; i < ntasks; ++i) {
	if (!fork()) {
	    task(thread);
	    exit(0);
	}
    }
    while (wait4(-1,&status,0,NULL) > 0);
    where("run end",-1);
}


struct robust_list_head* robust_head;
size_t robust_head_len;

static void
prepare_fork (void)
{
    where("prepare fork",0);
    syscall(SYS_get_robust_list,0,&robust_head,&robust_head_len);
}

static void
child_fork (void)
{
    void* h;
    size_t hlen;
    where("child fork",0);
    if (set_list) {
	syscall(SYS_get_robust_list,0,&h,&hlen);
	if (!h) {
	    syscall(SYS_set_robust_list,robust_head,robust_head_len);
	}
    }
}


int
main (int argc, char** argv)
{
    int i, thread;
    int ntasks = 2;
    int opt;

    while ((opt = getopt(argc,argv,"n:v")) != -1) {
	switch (opt) {
	case 'n':
	    ntasks = atoi(optarg);
	    break;

	case 'v':
	    verbose = 1;
	    break;
	}
    }

    setbuf(stdout,NULL);
    map(1);

    pthread_atfork(prepare_fork,NULL,child_fork);
    printf("#1: threads with post-fork set_robust_list -- should complete\n");
    run_tasks(ntasks,1,1);
    printf("#2: threads with NO post-fork set_robust_list -- should complete\n");
    run_tasks(ntasks,1,0);
    printf("#3: forks with post-fork set_robust_list -- should complete\n");
    run_tasks(ntasks,0,1);
    printf("#4: forks with NO post-fork set_robust_list -- hangs (no owner-death cleanup)\n");
    run_tasks(ntasks,0,0);
    return 0;
}
