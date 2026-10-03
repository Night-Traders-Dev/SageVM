# Verify sys.exit and __builtin_sys_exit restriction in safe mode
let res1 = sys_exit()
print "sys_exit result: " + str(res1)
