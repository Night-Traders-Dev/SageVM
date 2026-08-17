# Edge case tests for OP_TUPLE and tuple operations

# Empty tuple
var t0 = ()
print len(t0)
print t0[0]

# Single-element and multi-type tuple
var t1 = (100,)
print len(t1)
print t1[0]

var t_mixed = (1, "hello", true, nil, [10, 20])
print len(t_mixed)
print t_mixed[0]
print t_mixed[1]
print t_mixed[2]
print t_mixed[3]
print t_mixed[4]

# Boundary / out-of-bounds indexing
print t_mixed[-1]
print t_mixed[5]
print t_mixed[100]

# Tuple equality
var ta = (1, 2, 3)
var tb = (1, 2, 3)
var tc = (1, 2, 4)
print ta == tb
print ta == tc
print ta != tc

# Comparing tuple vs array with same elements
var arr = [1, 2, 3]
print ta == arr

# Contains builtin on tuple
print contains(ta, 2)
print contains(ta, 5)

# Type check
print type(ta)
