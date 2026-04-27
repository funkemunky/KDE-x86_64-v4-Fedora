#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include <errno.h>
#include <stdlib.h>
#include <netdb.h>  
#include <sys/mman.h>
#include <limits.h>
#include <unistd.h>


/*
In an  attempt to situate a stack frame over a 4GB boundary, we
first create a memory region which spans that boundary.  The
boundary which we are trying to span is arbitrarily chosen,
just make sure does not intersect with a region already in use.
*/

#define TARGET_BOUNDARY 0x3f600000000
#define MEM_REGION_SIZE 0x200000
#define MEM_REGION_START (TARGET_BOUNDARY - (MEM_REGION_SIZE/2))
#define KLUDGE_SPACE (-0x6e68)

int proto_tcp;
int port;

void *receiver(void *);
void *sender(void *);

int main(argc,argv)
int argc;
char *argv[];
{
	pthread_t server;
	pthread_t client;
	struct protoent *pe;
	void *stack_region;
	int ret;

	void  *stack_addr=(void *)(TARGET_BOUNDARY+KLUDGE_SPACE);
	size_t stack_size = 2 * PTHREAD_STACK_MIN;
	pthread_attr_t attr;


	/* set TCP port and protocol number */ 
	if (argc != 2 ) port=1027;
	else port = atoi(argv[1]);

	pe = getprotobyname("tcp");
	proto_tcp=pe->p_proto;


	if (pthread_attr_init(&attr) < 0) {
		perror("pthread_attr_init\n");
		exit(1);
	}

	/* creating the memory region */
	stack_region=mmap((void *)MEM_REGION_START,
		MEM_REGION_SIZE, PROT_READ|PROT_WRITE, 
		MAP_PRIVATE | MAP_ANON, (-1), 0);
	if (stack_region == MAP_FAILED) {
		perror("mmap\n");
		exit(1);
	}

	if (pthread_create(&server, NULL , sender, NULL) != 0){
		perror("pthread_create 1");
		exit(1);
	}


	if ((ret=pthread_attr_setstack(&attr,stack_addr,stack_size))!=0)
	{
		perror("pthread_attr_setstack");
		printf("ret = %d\n",ret);
		exit(1);
	}

	if ((ret=pthread_create(&client, &attr, receiver, NULL)) != 0){
		printf("pthread_create2 failed with %d\n",ret);
		exit(1);
	}

	pthread_join(server, NULL);
	pthread_join(client, NULL);

	exit(0);
}


void *sender(void *context){
	int ret;
	int sfd;	/* socket descriptor */
	int cfd;	/*  connection descriptor */
	struct sockaddr_in addr;
	char *p;
	char buffer[] = "Hello World!";

	if ((sfd = socket(PF_INET, SOCK_STREAM, proto_tcp)) < 0 )  {
		perror("sender socket\n");
		return(NULL);
	}

	addr.sin_family=AF_INET;
	addr.sin_port=htons(port);
	p=(gethostbyname("localhost")->h_addr_list[0]);
	memcpy(&(addr.sin_addr.s_addr),p,sizeof(p));

	if (bind(sfd, (struct sockaddr*)&addr, sizeof addr) < 0) {
		perror("sender bind\n");
		return(NULL);
	}

	if (listen(sfd, 1) == -1){
		perror("sender listen\n");
		return(NULL);
	}

	cfd = accept(sfd, NULL, NULL);
	if (cfd < 0 ) 
	{
		perror("accept\n");
		return(NULL);
	}

	if(send(cfd, (void*) buffer, sizeof(buffer), MSG_NOSIGNAL) == -1){
		perror("send");
		return(NULL);
	}

	shutdown(cfd, SHUT_RDWR); 

	return(NULL);
}

void *receiver(void *context){

	char buf[100];
	int sfd;
	struct sockaddr_in addr;
	char *p;
	ssize_t ret;

	addr.sin_family=AF_INET;
	addr.sin_port=htons(port);
	p=(gethostbyname("localhost")->h_addr_list[0]);
	memcpy(&(addr.sin_addr.s_addr),p,sizeof(p));

	sleep(1);

	if ((sfd = socket(PF_INET, SOCK_STREAM, proto_tcp)) < 0 ) {
		perror("receiver socket\n");
		return(NULL);
	}

	if(connect(sfd, (struct sockaddr*)&addr, sizeof addr) == -1){
		perror("connect\n");
		return(NULL);
	}

	if ((ret = recv(sfd, (void*)buf, sizeof(buf), MSG_WAITALL))<0) {
		perror("recv");
		return(NULL);
	} 

	buf[ret]='\0';
	printf("received \"%s\"\n",buf);

	shutdown(sfd, SHUT_RDWR);

	return(NULL);
}
