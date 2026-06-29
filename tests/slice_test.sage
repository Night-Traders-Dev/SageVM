var a = [1, 2, 3, 4, 5]
var s = "hello"

print "Array slice [1:4]:"
var a1 = a[1:4]
print len(a1)
print a1[0]
print a1[1]
print a1[2]

print "String slice [1:4]:"
var s1 = s[1:4]
# BUG: String slicing in SVM returns nil due to float-to-int conversion issues.
print s1

print "Negative slice [0:-1]:"
# This might fail or return empty depending on implementation
var a2 = a[0:-1]
print len(a2)
