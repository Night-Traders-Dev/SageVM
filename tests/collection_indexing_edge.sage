# Test collection indexing and mutation (OP_GET_INDEX, OP_SET_INDEX)
# across arrays, matrices, dictionaries, and boundary values.

print "--- Array Element Mutation & Expression Indices ---"
let arr = [10, 20, 30]
arr[1] = 99
print arr[1]
let idx = 1 + 1
arr[idx] = arr[0] + arr[1]
print arr[2]

print "--- Multi-dimensional Matrix Indexing & Mutation ---"
let matrix = [[1, 2], [3, 4]]
print matrix[0][1]
matrix[1][0] = 77
print matrix[1][0]

print "--- Array Out-of-Bounds Access ---"
print arr[10]

print "--- Dictionary Key Access & Mutation ---"
let dict = {"a": 1, "b": 2}
dict["a"] = 100
print dict["a"]
dict["c"] = 300
print dict["c"]
print dict["missing_key"]

print "--- Nested Dictionary Mutations ---"
let nested = {"inner": {"val": 50}}
print nested["inner"]["val"]
nested["inner"]["val"] = 500
print nested["inner"]["val"]
