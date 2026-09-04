# Test slice operator syntax and slice() builtin with negative indices and edge cases

var arr = [10, 20, 30, 40, 50]
var str_val = "SageLangVM"

print "--- Array slice operator with negative indices ---"
var a1 = arr[-3:]
print "arr[-3:] len: " + str(len(a1))
print a1[0]
print a1[1]
print a1[2]

var a2 = arr[:-2]
print "arr[:-2] len: " + str(len(a2))
print a2[0]
print a2[1]
print a2[2]

var a3 = arr[-4:-1]
print "arr[-4:-1] len: " + str(len(a3))
print a3[0]
print a3[1]
print a3[2]

print "--- String slice operator with negative indices ---"
print "str[-4:]: " + str_val[-4:]
print "str[:-2]: " + str_val[:-2]

print "--- Slice builtin with negative indices ---"
var b1 = slice(arr, -3, -1)
print "slice(arr, -3, -1) len: " + str(len(b1))
print b1[0]
print b1[1]

var b2 = slice(str_val, -6, -2)
print "slice(str_val, -6, -2): " + b2

print "--- Edge cases: out-of-range negative start and inverted range ---"
var e1 = slice(arr, -100, 3)
print "slice(arr, -100, 3) len: " + str(len(e1))
print e1[0]

var e2 = slice(arr, -1, -4)
print "slice(arr, -1, -4) len: " + str(len(e2))

var e3 = slice(str_val, -2, -5)
print "slice(str_val, -2, -5): '" + e3 + "'"
