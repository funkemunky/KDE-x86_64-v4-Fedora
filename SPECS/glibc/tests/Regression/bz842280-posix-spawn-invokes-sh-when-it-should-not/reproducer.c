#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <spawn.h>
#include <signal.h>
#include <fcntl.h>
#include <string.h>
/* if it uses fork() why bother? */
#undef fork
#define NOTE(a) fprintf(stderr,"%s\n",a)
pid_t fork (void) { NOTE("uses fork()"); return -1; }
pid_t _fork (void) { NOTE("uses _fork()"); return -1; }
pid_t __fork (void) { NOTE("uses __fork()"); return -1; }
int
main(argc, argv)
int	argc;
char**	argv;
{
	char*			s;
	pid_t			pid;
	posix_spawnattr_t	attr;
	int			n;
	int			status;
	char*			cmd[3];
	char			tmp[1024];
	if (argv[1])
		_exit(signal(SIGHUP, SIG_DFL) != SIG_IGN);
	signal(SIGHUP, SIG_IGN);
	if (posix_spawnattr_init(&attr))
	{
		NOTE("posix_spawnattr_init() FAILED");
		_exit(0);
	}
	if (posix_spawnattr_setpgroup(&attr, 0))
	{
		NOTE("posix_spawnattr_setpgroup() FAILED");
		_exit(0);
	}
	if (posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETPGROUP))
	{
		NOTE("posix_spawnattr_setflags() FAILED");
		_exit(0);
	}
	/* first try an a.out and verify that SIGHUP is ignored */
	cmd[0] = argv[0];
	cmd[1] = "test";
	cmd[2] = 0;
	if (posix_spawn(&pid, cmd[0], 0, &attr, cmd, 0))
	{
		NOTE("posix_spawn() FAILED");
		_exit(0);
	}
	status = 1;
	if (wait(&status) < 0)
	{
		NOTE("wait() FAILED");
		_exit(0);
	}
	if (status != 0)
	{
		NOTE("SIGHUP ignored in parent not ignored in child");
		_exit(0);
	}
	/* must return exec-type errors or its useless to us *unless* there is no [v]fork() */
	n = strlen(cmd[0]);
	if (n >= (sizeof(tmp) - 3))
	{
		NOTE("test executable path too long");
		_exit(0);
	}
	strcpy(tmp, cmd[0]);
	tmp[n] = '.';
	tmp[n+1] = 's';
	tmp[n+2] = 'h';
	tmp[n+3] = 0;
	if ((n = open(tmp, O_CREAT|O_WRONLY, S_IRWXU|S_IRWXG|S_IRWXO)) < 0 ||
	    chmod(tmp, S_IRWXU|S_IRWXG|S_IRWXO) < 0 ||
	    write(n, "exit 99\n", 8) != 8 ||
	    close(n) < 0)
	{
		NOTE("test script create FAILED");
		_exit(0);
	}
	cmd[0] = tmp;
	n = 0; /* 0 means reject */
	pid = -1;
	if (posix_spawn(&pid, cmd[0], 0, &attr, cmd, 0)) {
		n = 2; /* ENOEXEC produces posix_spawn() error => BEST */
		NOTE("ENOEXEC produces posix_spawn() error => BEST");
	}
	else if (pid == -1)
		NOTE("ENOEXEC returns pid == -1");
	else if (wait(&status) != pid)
		NOTE("ENOEXEC produces no child process");
	else if (!WIFEXITED(status))
		NOTE("ENOEXEC produces signal exit");
	else
	{
		status = WEXITSTATUS(status);
		if (status == 127)
		{
			NOTE("ENOEXEC produces exist status 127 => GOOD");
			n = 1; /* ENOEXEC produces exit status 127 => GOOD */
		}
		else if (status == 99)
			NOTE("ENOEXEC invokes sh");
		else if (status == 0)
			NOTE("ENOEXEC reports no error");
	}
	_exit(n);
}

