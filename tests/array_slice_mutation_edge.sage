print "--- 2D Matrix Creation and Slicing ---"
var matrix = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]

var sub_matrix = slice(matrix, 0, 2)
print sub_matrix

print "--- Slice Copy Independence on Element Mutation ---"
sub_matrix[0][0] = 99
print sub_matrix[0]
print matrix[0]

print "--- Zero-Length Slice ---"
var empty_slice = slice(matrix, 1, 1)
print empty_slice

print "--- Empty Array Slicing ---"
var empty_arr = []
print slice(empty_arr, 0, 5)

print "--- Slice Syntax Slicing on Matrix Row ---"
var row = matrix[1]
print row[0:2]
