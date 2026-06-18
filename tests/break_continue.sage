# Test break and continue
# NOTE: This test is expected to FAIL because OP_BREAK (49) and OP_CONTINUE (50)
# are currently unimplemented stubs in src/svm/sgvm_vm.sage and will halt execution.

print "Loop start"
var i = 0
while i < 5:
    i = i + 1
    if i == 3:
        continue
    if i == 4:
        break
    print i
print "Loop end"
