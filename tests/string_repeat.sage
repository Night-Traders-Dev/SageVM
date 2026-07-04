# Test string repetition
# BUG: SVM currently doesn't support string repetition with * and fails with
# "Runtime Error: Operands must be numbers."

print "a" * 3
print "abc" * 2
print "a" * 1
print "a" * 0
print "a" * -1
