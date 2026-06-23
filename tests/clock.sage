# Test clock() built-in
var t = clock()
print "Clock type:"
print type(t)
# We can't check the exact value, but it should be a number and >= 0
if t >= 0:
    print "Clock is non-negative"
else:
    print "Clock is negative!"
