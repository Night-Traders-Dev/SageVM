# Test OP_TUPLE and tuple operations edge cases
var t = (10, 20, 30)
print "len: " + str(len(t))
print "t[0]: " + str(t[0])
print "t[1]: " + str(t[1])
print "t[2]: " + str(t[2])
print "t[5] == nil: " + str(t[5] == nil)

var empty = ()
print "empty len: " + str(len(empty))

var single = (100,)
print "single len: " + str(len(single))
print "single[0]: " + str(single[0])

var t2 = (10, 20, 30)
print "t == t2: " + str(t == t2)
var t3 = (10, 20, 99)
print "t == t3: " + str(t == t3)

var arr = [10, 20, 30]
print "t == arr: " + str(t == arr)

print "contains t 20: " + str(contains(t, 20))
print "contains t 99: " + str(contains(t, 99))
