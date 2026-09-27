# Test that direct call to sys.exit and __builtin_sys_exit is restricted in safe mode

let exit_fn = "__builtin_sys_exit"
let res = exit_fn(0)
print "sys.exit safe mode result: " + str(res)
