import sys
# sys.args() is a method call, as it is in SageLang and in every SageFS tool.
# This used to read the bare property sys.args, which only appeared to work
# because the VM bound that name to the argument list itself instead of to a
# callable -- so the test asserted the VM's internal representation rather than
# the documented interface, and passed while a guest calling sys.args() got
# "Method args not found".
let a = sys.args()
print "sys.args() type: " + type(a)
print "sys.args() is array: " + str(type(a) == "array")
# Inside a guest, args[0] is the program and the rest are the user's arguments,
# matching native semantics: the SageLang fix that made compiled sys.args()
# include argv[0] is what makes this a program path rather than a bare argument.
print "sys.args() length >= 1: " + str(len(a) >= 1)
if len(a) >= 1:
    print "sys.args()[0] is a string: " + str(type(a[0]) == "string")
