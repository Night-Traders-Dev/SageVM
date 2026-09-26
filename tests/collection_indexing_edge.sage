# Nested array indexing & assignment
var matrix = [[1, 2], [3, 4]]
print "Matrix [1][0] before: " + str(matrix[1][0])
matrix[1][0] = 99
print "Matrix [1][0] after: " + str(matrix[1][0])

# Indexing with variable expressions
var idx = 0
matrix[idx][idx + 1] = 42
print "Matrix [0][1]: " + str(matrix[0][1])

# Non-string dictionary keys
# NOTE: Host SageVM dictionary indexing expects string keys; non-string keys
# like integers or booleans evaluate to nil upon indexing under SVM.
var dict = {}
dict[1] = "int_key"
dict[true] = "bool_key"
print "Dict [1]: " + str(dict[1])
print "Dict [true]: " + str(dict[true])

# Out of bounds index access and missing key
var arr = [10, 20]
print "Arr OOB: " + str(arr[5])
print "Dict missing: " + str(dict["missing"])

# Nested dict mutation
var nested_dict = {"a": {"b": 100}}
nested_dict["a"]["b"] = 200
print "Nested dict [a][b]: " + str(nested_dict["a"]["b"])
