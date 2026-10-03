import math

print "--- Standard 2x2 Matrix ---"
let m2x2 = [[1, 2], [3, 4]]
math.printm(m2x2)

print "--- Rectangular 2x3 Matrix ---"
let m2x3 = [[10, 20, 30], [40, 50, 60]]
math.printm(m2x3)

print "--- 1D Array as Vector Matrix ---"
let vec = [5, 10, 15]
math.printm(vec)

print "--- Empty Array Matrix ---"
let empty_mat = []
math.printm(empty_mat)

print "--- Mixed String/Number Matrix ---"
let mixed_mat = [["a", 1], [2, "b"]]
math.printm(mixed_mat)

print "--- Nil Parameter Input ---"
math.printm(nil)
