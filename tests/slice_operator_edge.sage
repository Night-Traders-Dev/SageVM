# Test array and string slice syntax edge cases (OP_SLICE)

var arr = [10, 20, 30, 40, 50]

print "--- Omitted start slice [:3] ---"
var s1 = arr[:3]
print len(s1)
print s1[0]
print s1[2]

print "--- Omitted end slice [2:] ---"
var s2 = arr[2:]
print len(s2)
print s2[0]
print s2[2]

print "--- Full array slice [:] ---"
var s3 = arr[:]
print len(s3)

print "--- Out of bounds slice [0:10] ---"
var s4 = arr[0:10]
print len(s4)

print "--- Start greater than end slice [4:2] ---"
var s5 = arr[4:2]
print len(s5)
