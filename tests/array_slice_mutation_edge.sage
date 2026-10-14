# Test array slice mutation and copy independence

print "1. 1D Array slicing & independence:"
var original = [10, 20, 30, 40, 50]
var sl = slice(original, 1, 4)
print "Original:"
print original
print "Slice:"
print sl

sl[0] = 999
print "After slice mutation - Original:"
print original
print "After slice mutation - Slice:"
print sl

print "2. 2D Matrix row slicing:"
var matrix = [[1, 2], [3, 4], [5, 6]]
var row_slice = slice(matrix, 0, 2)
print "Matrix row slice:"
print row_slice

row_slice[0][0] = 777
print "After inner element mutation on matrix:"
print matrix[0]

print "3. Boundary & zero-length slicing:"
var empty_arr = []
print "Empty array slice:"
print slice(empty_arr, 0, 5)

print "Zero length slice:"
print slice(original, 2, 2)

print "Start greater than end:"
print slice(original, 4, 2)
