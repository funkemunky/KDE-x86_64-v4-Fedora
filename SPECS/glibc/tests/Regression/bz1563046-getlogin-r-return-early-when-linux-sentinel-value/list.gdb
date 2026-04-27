set confirm off
set breakpoint pending on
b __getlogin_r_loginuid
run 1
b +18
continue
n
n
n
n
n
n
n
n
quit
