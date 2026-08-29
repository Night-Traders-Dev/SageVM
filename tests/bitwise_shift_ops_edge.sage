# Test bitwise shifts edge cases in SVM/SRVM.
# Standard left shift is handled via OP_SHIFT_LEFT, and right shift via OP_SHIFT_RIGHT.

print "--- Normal shifts ---"
print 10 << 2
print 10 >> 2
print 0 << 5
print 0 >> 5

print "--- Zero shift counts ---"
print 15 << 0
print 15 >> 0

print "--- Shift by 30 ---"
print 1 << 30
print 1073741824 >> 30

print "--- Nil operands ---"
print nil << 2
print 10 << nil
print nil >> 2
print 10 >> nil

print "--- Float operands ---"
print 10.5 << 1
print 10 << 1.5
print 10.5 >> 1
print 10 >> 1.5
