# Test Local Variables
# NOTE: This test is expected to FAIL because OP_GET_LOCAL (88) and OP_SET_LOCAL (89)
# are not yet implemented in src/svm/sgvm_vm.sage.

proc test_locals():
    var x = 10
    var y = 20
    print x + y

test_locals()
