print "--- Basic Array Mutation & Access ---"
var arr = [10, 20, 30]
print "Initial len:"
print len(arr)

arr[1] = 99
print "arr[1] after assign:"
print arr[1]

print "--- Push and Pop Operations ---"
push(arr, 40)
print "len after push(40):"
print len(arr)
print "arr[3]:"
print arr[3]

var popped = pop(arr)
print "popped value:"
print popped
print "len after pop:"
print len(arr)

print "--- Nested Array Mutation ---"
var matrix = [[1, 2], [3, 4]]
print "matrix[1][0] before:"
print matrix[1][0]

matrix[1][0] = 77
print "matrix[1][0] after:"
print matrix[1][0]

print "--- Edge Cases: OOB & Pop Empty ---"
var empty_arr = []
var p_empty = pop(empty_arr)
print "pop empty array:"
print p_empty

print "OOB index access:"
print arr[100]
