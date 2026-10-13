# Test array slice operations, copy independence on mutation, matrix slice access, and boundary slice values

print "--- Matrix row slicing and element mutation ---"
var matrix = [
    [1, 2, 3],
    [10, 20, 30],
    [100, 200, 300]
]

var slice1 = matrix[1][0:2]
print "slice1 len: " + str(len(slice1))
print "slice1[0]: " + str(slice1[0])
print "slice1[1]: " + str(slice1[1])

print "--- Verify slice copy independence ---"
slice1[0] = 999
print "slice1[0] after mutation: " + str(slice1[0])
print "matrix[1][0] original value: " + str(matrix[1][0])

print "--- Slice beyond length bounds ---"
var arr = [5, 10, 15]
var over_slice = arr[1:100]
print "over_slice len: " + str(len(over_slice))
print "over_slice[0]: " + str(over_slice[0])
print "over_slice[1]: " + str(over_slice[1])

print "--- Zero-length slice (start == end) ---"
var zero_slice = arr[1:1]
print "zero_slice len: " + str(len(zero_slice))

print "--- Slicing empty array ---"
var empty_arr = []
var empty_slice = empty_arr[0:5]
print "empty_slice len: " + str(len(empty_slice))
