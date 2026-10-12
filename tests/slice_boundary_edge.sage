# Test slice operator and slice() builtin with edge boundary values, clamping, and zero length targets.

var arr = [100, 200, 300, 400, 500]
var str_val = "SageLang"

print "--- Array slice exact full copy ---"
var a_full = slice(arr, 0, len(arr))
print "Full len: " + str(len(a_full))
print a_full[0]
print a_full[4]

print "--- Array slice zero length (same start and end) ---"
var a_zero = slice(arr, 2, 2)
print "Zero len: " + str(len(a_zero))

print "--- Array slice clamping extreme start/end ---"
var a_clamp = slice(arr, -50, 100)
print "Clamp len: " + str(len(a_clamp))
print a_clamp[0]
print a_clamp[4]

print "--- String slice zero length ---"
var s_zero = slice(str_val, 3, 3)
print "Str zero len: '" + s_zero + "'"

print "--- String slice clamping extreme start/end ---"
var s_clamp = slice(str_val, -100, 50)
print "Str clamp: " + s_clamp

print "--- Empty collection slicing ---"
var emp_arr = slice([], 0, 5)
print "Empty arr slice len: " + str(len(emp_arr))
var emp_str = slice("", 0, 5)
print "Empty str slice: '" + emp_str + "'"
