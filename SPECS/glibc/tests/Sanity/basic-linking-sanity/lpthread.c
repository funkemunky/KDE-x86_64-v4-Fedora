#include <pthread.h>
#include <stdio.h>

FILE *fp;
pthread_mutex_t mutech = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t cond = PTHREAD_COND_INITIALIZER;
int counter = 0;

void *one(void *arg){
  pthread_mutex_lock(&mutech);
  while (counter == 0)
    pthread_cond_wait(&cond, &mutech);

  counter = 2;
  fprintf(fp, "Thread 1 run\n");

  pthread_mutex_unlock(&mutech);
  pthread_cond_signal(&cond);
}

void *two(void *arg){
  pthread_mutex_lock(&mutech);
  while(counter == 1)
    pthread_cond_wait(&cond, &mutech);

  counter = 1;
  fprintf(fp, "Thread 2 run\n");

  pthread_mutex_unlock(&mutech);
  pthread_cond_signal(&cond);
}


int main(){
  fp = fopen("lpthread.out", "w");
  pthread_t on;
  pthread_t tw;
  pthread_create(&on, NULL, one, NULL);
  pthread_create(&tw, NULL, two, NULL);

  pthread_join(tw, NULL);
  pthread_join(on, NULL);

  fclose(fp);
  return 0;
}
