# Test array and string length
var a = [1, 2, 3, 4, 5]
print len(a)
var s = "Hello"
print len(s)

# Test array slicing
var a2 = slice(a, 1, 4)
print len(a2)
print a2[0]
print a2[1]
print a2[2]

# Test string slicing
# BUG: String slicing in the SVM VM (src/svm/sgvm_vm.sage) fails with nil
# for strings if indices are passed as doubles/floats from the constant pool;
# the host slice function requires explicit integer casting for reliable indexing.
var s2 = slice(s, 1, 4)
print s2
