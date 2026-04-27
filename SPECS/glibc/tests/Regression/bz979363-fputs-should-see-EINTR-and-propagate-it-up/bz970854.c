/* This is a reproducer for BZ#970854.
 * https://bugzilla.redhat.com/show_bug.cgi?id=970854
 */
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <sys/wait.h>

/* Signal number of caught signal.  */
int caught_sig;
/* Pipe used to simulate the EINTR return.  */
int pfd[2];
/* General purpose buffer.  */
#define BLK_SIZE 512
char buf[BLK_SIZE];
/* Alarm counter.  */
int alrm_flag = 0;

#define SPEEDFACTOR (3)
#define WAITTIME (5*SPEEDFACTOR)
#define NSIG 32

/* Enable or disable debug printf.  */
#define DPRINTF(...) printf(__VA_ARGS__)
// #define DPRINTF(...) do {} while (0)

/* Signal function to check timeouts.  */
void
alrm (int signal)
{
  ++alrm_flag;
}

#define NULLSA ((struct sigaction *)0)

/* Timeout function.  */
#define SET_TIMEOUT(waittime) \
        { \
                unsigned to_unslept, to_alrm, to_time; \
                int to_err, to_flag, to_ret; \
                struct sigaction to_alrm_sa, to_old_sa; \
                to_time = (waittime); \
                to_flag = 0; \
                alrm_flag = 0; \
                to_alrm_sa.sa_handler = alrm; \
                to_alrm_sa.sa_flags = 0; \
                (void) sigemptyset(&to_alrm_sa.sa_mask); \
                to_alrm = alarm(0); \
                to_ret = sigaction(SIGALRM, &to_alrm_sa, &to_old_sa); \
                if (to_ret != 0) \
                    DPRINTF("SET_TIMEOUT: sigaction(SIGALRM, ...) failed"); \
                if (to_alrm != 0) { \
                        if (to_time < to_alrm) { \
                                ++to_flag; \
                                to_alrm -= to_time; \
                        } else { \
                                --to_flag; \
                                to_time = to_alrm; \
                                to_alrm = 0; \
                                (void) sigaction(SIGALRM, &to_old_sa, NULLSA); \
                        } \
                } \
                (void) alarm(to_time);


#define CLEAR_ALARM \
                to_err = errno; \
                to_unslept = alarm(0); \
                if (to_flag >= 0) \
                        (void) sigaction(SIGALRM, &to_old_sa, NULLSA); \
                if (to_flag > 0 || (to_flag < 0 && to_unslept != 0)) \
                        (void) alarm(to_alrm + to_unslept); \
                errno = to_err; \
        }


void
sig_catch (int signal)
{
  caught_sig = signal;
}

int
main (void)
{
  int ret;
  pid_t child;
  struct sigaction act;
  int fd, flags;
  int written, count;
  FILE *fp;

  act.sa_handler = sig_catch;
  act.sa_flags = 0;
  sigemptyset (&act.sa_mask);

  /* Create a pipe for using with a child process that will write to
     the pipe via fputs.  */
  ret = pipe (pfd);
  if (ret != 0)
    {
      perror ("pipe");
      exit (1);
    } 

  /* Work with the write side of the pipe.  */
  fd = pfd[1];

  /* Set the pipe into non-blocking mode.
     We do this to fill up the pipe without blocking.  */
  flags = fcntl (fd, F_GETFL);
  if (flags == -1)
    {
      perror ("fcntl (F_GETFL)");
      exit (1);
    }
  flags |= O_NONBLOCK;
  ret = fcntl (fd, F_SETFL, flags);
  if (ret == -1)
    {
      perror ("fcntl (F_SETFL)");
      exit (1);
    }
  /* Fill the write side of the pipe.  */
  /* Fill BLK_SIZE at a time... */
  do
  {
    written = write (fd, buf, BLK_SIZE);
    if (written == -1)
      {
        DPRINTF ("write (BLK_SIZE), written = %d, errno = %d\n", written, errno);
      }
    else
      count += written;
  }
  while (written > 0);
  /* Fill the remainder char at a time... */
  do
  {
    written = write (fd, "z", 1);
    if (written == -1)
      {
        DPRINTF ("write (z), errno = %d\n", errno);
      }
    else
      count += written;
  }
  while (written > 0);
  DPRINTF ("Wrote %d bytes to write side of pipe.\n", count);
  /* Set pipe to blocking now.  */
  flags = fcntl (fd, F_GETFL);
  if (flags == -1)
    {
      perror ("fcntl (F_GETFL)");
      exit (1);
    }
  flags &= ~O_NONBLOCK;
  ret = fcntl (fd, F_SETFL, flags);
  if (ret == -1)
    {
      perror ("fcntl (F_SETFL)");
      exit (1);
    }
  /* Get a stream for child fputs.  */
  fp = fdopen (fd, "w");
  if (fp == NULL)
    {
      perror ("fopen");
      exit (1);
    }
  /* Unbuffer the stream... */
  /* Original uses setbuf (fp, (char *) NULL); */
  ret = setvbuf (fp, (char *) NULL, _IONBF, 0); 
  if (ret != 0)
    {
      perror ("setvbuf");
      exit (1);
    }
  /* Start the alarm counting...  */
  SET_TIMEOUT (2 * WAITTIME)
  child = fork ();


  if (child == 0)
    {
      pid_t selfid __attribute__ ((__unused__));
      int i;
      /* In the child.  */
      DPRINTF ("child: In the child\n");
      selfid = getpid ();
      DPRINTF ("child: Child pid is %d\n", (int) selfid);

      /* Set all signals to SIG_DFL, except for SIGKILL, SIGSTOP, and SIGCHLD.  */
      for (i = 1; i < NSIG; i++)
        {
          int ret;
	  struct sigaction sig;
	  if (i == SIGKILL || i == SIGSTOP || i == SIGCHLD)
	    continue;
	  ret = sigaction (i, NULLSA, &sig);
	  if (ret != 0)
	    {
	      perror ("sigaction - get signal setting");
	      _exit (1);
	    }
	  if (sig.sa_handler != SIG_IGN)
	    {
	      sig.sa_handler = SIG_DFL;
	      sig.sa_flags = 0;
	      ret = sigemptyset (&sig.sa_mask);
	      if (ret != 0)
		{
		  perror ("sigemptyset - set empty set");
		  _exit (1);
		}
	      ret = sigaction (i, &sig, NULLSA);
	      if (ret != 0)
		{
		  perror ("sigaction - set SIG_DFL");
		  _exit (1);
		}
	    }

        }
      /* Call alrm when SIGALRM is delivered.  */
      struct sigaction new, old;
      int saved_errno;
      new.sa_handler = alrm;
      new.sa_flags = 0;
      sigemptyset (&new.sa_mask);
      ret = sigaction (SIGALRM, &new, &old);
      if (ret != 0)
        {
	  perror ("sigaction - set SIGALRM action");
	  _exit (1);
        }
      /* Deliver an alarm in WAITTIME seconds... */
      alarm (WAITTIME);
      /* Try to write to a blocking stream that is full... */
      ret = fputs("test string", fp);
      saved_errno = errno;
      /* Alarm should trigger.  */
      if (ret < 0)
        {
	  DPRINTF ("fputs errno is %d\n", saved_errno);
        }
      if (saved_errno == EINTR)
	printf ("PASS: fputs blocked on a pipe returned EINTR when interrupted by signal.\n");
      else
	{
          printf ("FAIL: fputs blocked on a pipe returned errno %d instead of EINTR.\n", saved_errno);
	  _exit (1);
	}

      if (alrm_flag > 0) 
	{
	  DPRINTF ("child: alrm_flag was %d\n", alrm_flag);
	}
      _exit (0);
    }
  else
    {
      /* In the parent.  */
      pid_t wid;
      int status, wstatus __attribute__ ((__unused__));
      DPRINTF ("parent: In the parent\n");
      DPRINTF ("parent: Child pid is %d\n", (int) child);
      wid = waitpid (child, &status, 0);
      if (wid == -1)
	{
	  perror ("waitpid");
	  if (alrm_flag > 0)
	    {
	      printf ("FAIL: child process timed out.\n");
	    }
	  exit (1);
	}
      DPRINTF ("child status was %d\n", status);
      if (!WIFEXITED(status))
	{
	  printf ("FAIL: child did not exit normally.\n");
	}
      else
	{
	  wstatus = WEXITSTATUS(status);
	  DPRINTF ("child exit status was: %d\n", wstatus);
	}
    }
  /* ... clear the alarm. We are done the test.  */
  CLEAR_ALARM
  if (alrm_flag > 0)
    printf ("FAIL: test function timed out\n");
  close (pfd[0]);
  close (pfd[1]);
  fclose (fp);
  return 0;
}
