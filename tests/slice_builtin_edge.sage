# Test slice builtin and slice opcode edge cases
var arr = [10, 20, 30, 40, 50]
var str_val = "Hello World"

print "Normal array slice:"
var s1 = slice(arr, 1, 4)
print len(s1)
print s1[0]
print s1[2]

print "Out of bounds array slice (end > len):"
var s2 = slice(arr, 2, 10)
print len(s2)

print "Reverse/invalid array slice (start > end):"
var s3 = slice(arr, 4, 2)
print len(s3)

print "Normal string slice:"
var st1 = slice(str_val, 0, 5)
print st1

print "String slice with start > end:"
var st2 = slice(str_val, 5, 2)
print st2

print "String slice out of bounds:"
var st3 = slice(str_val, 6, 20)
print st3

print "Slice nil input:"
print slice(nil, 0, 2)
