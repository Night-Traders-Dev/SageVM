# Test sys.exec and sys.system features in SVM backend.

import sys

print "Testing sys.exec..."
var res1 = sys.exec("echo Executed successfully")
print "Result of sys.exec: " + str(res1)

print "Testing sys.system..."
# Under SVM, this dispatches via sys_exec but still functions as executing a system command.
var res2 = sys.system("echo System call executed")
print "Result of sys.system: " + str(res2)
