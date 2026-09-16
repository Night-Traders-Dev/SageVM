# Test string concatenation (OP_ADD) with different operand types.

print "--- String + Number ---"
print "Count: " + 42
print 3.14 + " is pi"

print "--- String + Boolean ---"
print "Status: " + true
print false + " is status"

print "--- String + Nil ---"
print "Value: " + nil
print nil + " item"

print "--- String + Array / Dict ---"
let arr = [1, 2]
let d = {"key": "val"}
print "Array: " + arr
print "Dict: " + d

print "--- Multiple Concat Chain ---"
print "Val: " + 10 + " / " + true + " / " + nil
