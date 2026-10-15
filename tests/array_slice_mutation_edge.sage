# Test array slice operator and slice() builtin on 2D matrices, verifying
# copy independence on element mutation, zero-length slices, and empty array slicing.

print "--- Array Slice & Mutation Independence ---"
var orig = [10, 20, 30, 40, 50]
var sl = slice(orig, 1, 4)
print sl[0]
print sl[1]
print sl[2]

print "--- Mutating Slice Does Not Mutate Original ---"
sl[0] = 999
print sl[0]
print orig[1]

print "--- Mutating Original Does Not Mutate Slice ---"
orig[2] = 888
print orig[2]
print sl[1]

print "--- 2D Matrix Slicing ---"
var matrix = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]
var row_slice = slice(matrix, 0, 2)
print len(row_slice)
print row_slice[0][0]
print row_slice[1][2]

print "--- Zero Length & Empty Slices ---"
var empty_sl = slice(orig, 2, 2)
print len(empty_sl)

var arr_empty = []
var sl_from_empty = slice(arr_empty, 0, 0)
print len(sl_from_empty)
