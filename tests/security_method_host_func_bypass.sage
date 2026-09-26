# Test that restricted builtins via method call dispatch are restricted in safe mode
let d = {"exec": "__builtin_sys_exec", "getenv": "__builtin_sys_getenv"}
print "Calling restricted builtins via method dispatch:"
d.exec("echo hacked")
d.getenv("PATH")
print "done"
