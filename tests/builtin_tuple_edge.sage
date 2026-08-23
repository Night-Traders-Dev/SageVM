# Tuple operations and edge cases
var t1 = (1, 2, 3)
print len(t1)
print t1[0]
print t1[2]
print t1[3]

var t2 = (42,)
print len(t2)
print t2[0]

var empty_tuple = ()
print len(empty_tuple)

var is_in1 = contains(t1, 2)
print is_in1

var is_in2 = contains(t1, 99)
print is_in2

var arr = [1, 2, 3]
print t1 == arr
print t1 == (1, 2, 3)
