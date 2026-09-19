# Test array concatenation via OP_ADD and edge cases
# OP_ADD handles:
# 1. Number + Number -> addition
# 2. String + Any / Any + String -> string concatenation
# 3. Array + Array -> array concatenation (elements appended)
# 4. Fallback: Array + non-array or other types -> fallback evaluation to 0 if not numbers

print "--- Normal Array Concatenation ---"
var arr1 = [1, 2, 3]
var arr2 = [4, 5, 6]
var res1 = arr1 + arr2
print "len(res1): " + str(len(res1))
print "res1[0]: " + str(res1[0])
print "res1[2]: " + str(res1[2])
print "res1[3]: " + str(res1[3])
print "res1[5]: " + str(res1[5])

print "--- Empty Array Concatenation ---"
var empty = []
var res2 = empty + [10, 20]
print "len(res2): " + str(len(res2))
print "res2[0]: " + str(res2[0])
print "res2[1]: " + str(res2[1])

var res3 = [30, 40] + empty
print "len(res3): " + str(len(res3))
print "res3[0]: " + str(res3[0])
print "res3[1]: " + str(res3[1])

print "--- Nested Array Concatenation ---"
var nested1 = [[1, 2]]
var nested2 = [[3, 4], [5]]
var res4 = nested1 + nested2
print "len(res4): " + str(len(res4))
print "len(res4[0]): " + str(len(res4[0]))
print "res4[0][0]: " + str(res4[0][0])
print "res4[1][1]: " + str(res4[1][1])

print "--- Mixed Types and Coercion Edge Cases ---"
var str_arr = ["a"] + [true, nil]
print "len(str_arr): " + str(len(str_arr))
print "str_arr[0]: " + str(str_arr[0])
print "str_arr[1]: " + str(str_arr[1])
print "str_arr[2] == nil: " + str(str_arr[2] == nil)

print "--- Array + String Coercion ---"
var arr_str = [1, 2] + "hello"
print "arr_str: " + str(arr_str)

print "--- Array + Non-array / Non-string Fallback ---"
var arr_num = [1, 2] + 5
print "arr_num: " + str(arr_num)
