print "--- 1D Array Slice Copy Independence ---"
var orig = [10, 20, 30, 40, 50]
var s = orig[1:4]
print s
print len(s)

orig[2] = 999
print orig
print s

s[0] = 888
print orig
print s

print "--- 2D Matrix Slicing ---"
var matrix = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]
var sub_matrix = matrix[0:2]
print sub_matrix
print len(sub_matrix)

matrix[0][1] = 777
print sub_matrix[0][1]

print "--- Boundary and Empty Array Slicing ---"
var empty_arr = []
print empty_arr[0:5]
print len(empty_arr[0:5])

print orig[3:3]
print len(orig[3:3])

print "--- Slice Builtin vs Slice Syntax ---"
var built_slice = slice(orig, 0, 2)
print built_slice
print orig[0:2]
