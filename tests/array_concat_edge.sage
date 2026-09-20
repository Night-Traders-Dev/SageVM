# Test array concatenation (OP_ADD / + operator) on normal and edge conditions.

print "--- Normal array concatenation ---"
var a1 = [1, 2]
var a2 = [3, 4]
var res1 = a1 + a2
print "res1 len: " + str(len(res1))
print "res1[0]: " + str(res1[0])
print "res1[1]: " + str(res1[1])
print "res1[2]: " + str(res1[2])
print "res1[3]: " + str(res1[3])

print "--- Empty array concatenation ---"
var empty = []
var res_empty = empty + empty
print "empty + empty len: " + str(len(res_empty))

var res_left_empty = [] + [10, 20]
print "left empty len: " + str(len(res_left_empty))
print "left empty[0]: " + str(res_left_empty[0])

print "--- Nested arrays concatenation ---"
var nest1 = [[1, 2]]
var nest2 = [[3, 4], [5]]
var res_nest = nest1 + nest2
print "nested len: " + str(len(res_nest))
print "nested[0][0]: " + str(res_nest[0][0])
print "nested[1][0]: " + str(res_nest[1][0])
print "nested[2][0]: " + str(res_nest[2][0])

print "--- Array + String concatenation ---"
var str_concat1 = [1, 2] + "hello"
print "array + string: " + str(str_concat1)

var str_concat2 = "hello" + [1, 2]
print "string + array: " + str(str_concat2)

# NOTE / SUSPECTED BUG: In OP_ADD (sgvm_vm.sage), adding an array to a non-array, non-string
# operand (e.g., [1, 2] + 5 or [1, 2] + nil) falls through to the non-numeric addition branch
# and returns 0 instead of raising a type error or appending the element.
print "--- Array + Non-array/non-string concatenation ---"
var num_concat = [1, 2] + 5
print "array + number: " + str(num_concat)

var nil_concat = [1, 2] + nil
print "array + nil: " + str(nil_concat)

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
