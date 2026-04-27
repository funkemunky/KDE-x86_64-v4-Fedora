/*
To build:

With system libc:
  gcc -o libdl_bug libdl_bug.c -ldl -pthread

With custom libc
  libc_dir=/path/to/glibc/install
  gcc -o libdl_bug libdl_bug.c -L$libc_dir/lib -Wl,--rpath=$libc_dir/lib \
      -Wl,--dynamic-linker=$libc_dir/lib/ld-linux-x86-64.so.2 -ldl -pthread

./libdl_bug bad_free is just a sanity check that valgrind will notice if
|&do_not_free_this| is accidentally passed to |free|.

Otherwise, this tool will allocate a |pthread_key_t| (which will likely be zero)
and store |&do_not_free_this| in it. The |pthread_key_t| has no destructor, so
this is perfectly valid.

It will then optionally call |dlerror| (pass dlerror vs no_dlerror to the tool),
and then return from |main| cleanly. At this point, when running under valgrind,
vg_preloaded.c will call |__libc_freeres|.

In glibc after 2827ab990aefbb0e53374199b875d98f116d6390 (2.28 and later),
|__libc_freeres| will call |__libdl_freeres|, which calls |free_key_mem| in
dlerror.c. That function cleans up |dlerror|'s thread-local state, but has a
bug: if nothing has called |dlerror|, there is no thread-local state and the
|pthread_key_t| is uninitialized! It then blindly calls |free| on the zero key,
and hits our |&do_not_free_this|. That results in an error in valgrind:

$ valgrind -q ./libdl_bug dlerror
Initializing a pthread_key_t.
key = 0
Setting thread local to &do_not_free_this.
Calling dlerror.
Exiting

$ valgrind -q ./libdl_bug no_dlerror
Initializing a pthread_key_t.
key = 0
Setting thread local to &do_not_free_this.
Exiting
==139993== Invalid free() / delete / delete[] / realloc()
==139993==    at 0x4C2FFA8: free (vg_replace_malloc.c:540)
==139993==    by 0x4E3D6D9: free_key_mem (dlerror.c:223)
==139993==    by 0x4E3D6D9: __dlerror_main_freeres (dlerror.c:239)
==139993==    by 0x53BFDC9: __libc_freeres (in /[...]/lib/libc-2.29.9000.so)
==139993==    by 0x4A296DB: _vgnU_freeres (vg_preloaded.c:77)
==139993==    by 0x5296381: __run_exit_handlers (exit.c:132)
==139993==    by 0x52963A9: exit (exit.c:139)
==139993==    by 0x528105D: (below main) (libc-start.c:342)
==139993==  Address 0x30a08c is 0 bytes inside data symbol "do_not_free_this"
==139993== 
*/

#include <dlfcn.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void usage(const char *prog_name) {
  fprintf(stderr, "Usage: %s [bad_free|no_dlerror|dlerror]\n", prog_name);
  exit(1);
}

static int do_not_free_this;
static pthread_key_t key;

int main(int argc, char **argv) {
  if (argc != 2) {
    usage(argv[0]);
  }

  if (strcmp(argv[1], "bad_free") == 0) {
    printf("Calling free(&do_not_free_this). Valgrind should notice.\n");
    free(&do_not_free_this);
  } else if (strcmp(argv[1], "no_dlerror") == 0 ||
             strcmp(argv[1], "dlerror") == 0) {
    printf("Initializing a pthread_key_t.\n");
    if (pthread_key_create(&key, NULL)) {
      perror("pthread_key_create");
      exit(1);
    }

    printf("key = %d\n", key);

    printf("Setting thread local to &do_not_free_this.\n");
    if (pthread_setspecific(key, &do_not_free_this) != 0) {
      perror("pthread_setspecific");
      exit(1);
    }

    if (strcmp(argv[1], "dlerror") == 0) {
      printf("Calling dlerror.\n");
      dlerror();
    }
  } else {
    usage(argv[0]);
  }
  printf("Exiting\n");
  return 0;
}
