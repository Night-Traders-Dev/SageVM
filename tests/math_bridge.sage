import math

print "math.pi: " + str(math.pi > 3.1)
# math.abs and math.sqrt are native functions.
# svm/sgvm_vm.sage has a call bridge but it might be failing for some reason.
# Looking at call_builtin, math.abs is NOT there.
# Looking at OP_IMPORT "math", it only defines pi, e, abs, sqrt, sin, cos, printm.
# But it maps them to host functions.

print "math.abs(-10): " + str(math.abs(-10))
print "math.sqrt(16): " + str(math.sqrt(16))
