# Test array slice operator syntax [s:e] and slice() builtin,
# copy independence on element mutation, 2D matrix slices, 0-length slices, and boundary cases.

print "--- 1D Array Slicing & Copy Independence ---"
var orig = [10, 20, 30, 40, 50]
var sub = orig[1:4]
print "orig: " + str(orig)
print "sub (orig[1:4]): " + str(sub)

# Mutate slice
sub[0] = 999
print "After sub[0] = 999:"
print "sub: " + str(sub)
print "orig (unaffected): " + str(orig)

print "--- slice() Builtin vs Syntax Parity ---"
var b_sub = slice(orig, 0, 3)
print "slice(orig, 0, 3): " + str(b_sub)

print "--- 2D Matrix Row Slicing ---"
var matrix = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]
var rows = matrix[1:3]
print "matrix rows[1:3]: " + str(rows)

print "--- Boundary Cases & Empty Slices ---"
var empty = []
print "empty[0:2]: " + str(empty[0:2])
print "orig[3:3] (0-length): " + str(orig[3:3])
print "orig[4:2] (start > end): " + str(orig[4:2])
print "orig[0:100] (overflow end): " + str(orig[0:100])
