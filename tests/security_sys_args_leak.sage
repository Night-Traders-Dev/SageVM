# Test that direct calls to sys.args and __builtin_sys_args are restricted in safe mode

let args_fn = "__builtin_sys_args"
let res = args_fn()
print "sys.args safe mode result: " + str(res)
