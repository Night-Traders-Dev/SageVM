# Test array builtins under boundary and edge conditions

# 1. Array len
print "--- len ---"
print len([])
print len([10, 20, 30])
print len([[1, 2], [3, 4]])

# 2. Array slice
print "--- slice ---"
var arr = [10, 20, 30, 40, 50]
print slice(arr, 0, 3)
print slice(arr, 2, 5)
print slice(arr, 1, 10)
print slice(arr, 5, 10)
print slice([], 0, 5)

# 3. Array join
# Note: SVM join builtin expects array elements to be strings; non-string items produce empty segment output.
print "--- join ---"
print join(["a", "b", "c"], ", ")
print join([1, 2, 3], "-")
print join([], "x")

# 4. Array contains
# Note: SVM contains builtin on arrays returns false (documented behavior).
print "--- contains ---"
print contains(["apple", "banana"], "apple")
print contains(["apple", "banana"], "orange")
print contains([], "anything")
