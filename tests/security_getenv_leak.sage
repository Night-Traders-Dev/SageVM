let getenv = "__builtin_sys_getenv"
let val = getenv("TEST_ENV_VAR")
if val == nil:
    print "SUCCESS: getenv blocked or returned nil"
else:
    print "VULNERABLE: getenv leaked environment variable: " + str(val)
