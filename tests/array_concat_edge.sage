# Test array concatenation and array addition behavior under normal and edge conditions.

print "--- Normal array concatenation ---"
let a1 = [10, 20]
let a2 = [30, 40]
let concat1 = a1 + a2
print "len(a1 + a2): " + str(len(concat1))
print "concat1[0]: " + str(concat1[0])
print "concat1[1]: " + str(concat1[1])
print "concat1[2]: " + str(concat1[2])
print "concat1[3]: " + str(concat1[3])

print "--- Array + String coercion ---"
let str_concat = [1, 2] + "hello"
print "array + string: " + str(str_concat)

print "--- Nested array concatenation ---"
let nested1 = [[1], [2]]
let nested2 = [[3], [4]]
let nested_concat = nested1 + nested2
print "len(nested_concat): " + str(len(nested_concat))
print "nested_concat[0]: " + str(nested_concat[0][0])
print "nested_concat[2]: " + str(nested_concat[2][0])

print "--- Empty array concatenation ---"
let empty1 = []
let empty2 = [100, 200]
let res_empty = empty1 + empty2
print "len([] + [100, 200]): " + str(len(res_empty))
print "res_empty[0]: " + str(res_empty[0])

print "--- Non-array / Non-string addition to array ---"
print "[1, 2] + nil: " + str([1, 2] + nil)
print "[1, 2] + 5: " + str([1, 2] + 5)
print "[1, 2] + true: " + str([1, 2] + true)
