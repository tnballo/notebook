#ifdef RUNTIME

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <dlfcn.h>

/* 
 * Usage (gcc-multilib for 32-bit compile): 
 * 
 * gcc -m32 -DRUNTIME -shared -fpic -ldl -o ptrace_interpose.so ptrace_interpose.c 
 * LD_PRELOAD="./ptrace_interpose.so" ltrace ./target_binary 
 */

const int error_ret = -1;
const int fake_ret = 0;

/* 
 * Malicious ptrace wrapper, surpresses error returns. Int for first arg instead of enum type. 
 */
long ptrace(int request, pid_t pid, void *addr, void *data) {

    long (*ptrace_func_ptr)(int request, pid_t pid, void *addr, void *data);
    char *error_msg;
    long real_ret;

    /* Get address of next occurance of a shared library ptrace */
    ptrace_func_ptr = dlsym(RTLD_NEXT, "ptrace");

    if ((error_msg = dlerror()) != NULL) {

        fputs(error_msg, stderr);
        exit(1);

    }

    /* Call the "real" ptrace. Need to preserve return in case of PTRACE_PEEK* requests */
    real_ret = ptrace_func_ptr(request, pid, addr, data);

    if (real_ret == error_ret) {

        return fake_ret;

    } else {

        return real_ret;

    }
    
}

#endif
