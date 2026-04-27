#include <stdio.h>
#include <execinfo.h>

void call_backtrace(){
        void * callstack[128];
        backtrace(callstack, 128);
}

int main(){
    call_backtrace();
    return 0;
}
