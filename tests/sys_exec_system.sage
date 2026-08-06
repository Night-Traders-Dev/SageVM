# Test sys.exec and sys.system features in SVM backend.
# CONFORMANCE BUG/GAP: In src/svm/sgvm_vm.sage, OP_IMPORT maps "sys"'s "system"
# property to "__builtin_sys_exec" (calling sys_exec) rather than
# "__builtin_sys_system" (which would invoke sys_system).
# Thus, calling sys.system will execute via sys_exec in SVM instead of the proper sys_system handler.

import sys

print "Testing sys.exec..."
var res1 = sys.exec("echo Executed successfully")
print "Result of sys.exec: " + str(res1)

print "Testing sys.system..."
# Under SVM, this dispatches via sys_exec but still functions as executing a system command.
var res2 = sys.system("echo System call executed")
print "Result of sys.system: " + str(res2)
