# Test math.printm() / OP_MATH_PRINTM matrix formatting builtin across 2D rectangular matrices,
# 1D arrays, non-array types, empty matrices, nested arrays with strings/floats/bools, and matrices with nil elements.

import math

print "--- 2D Rectangular Matrix ---"
math.printm([[1, 2, 3], [4, 5, 6]])

print "--- 2D Matrix with Mixed Primitive Types ---"
math.printm([["row1", true, 3.14], [nil, false, 42]])

print "--- 1D Flat Array ---"
math.printm([10, 20, 30])

print "--- Empty Matrix ---"
math.printm([])

print "--- Matrix with Empty Sub-arrays ---"
math.printm([[], [1]])

print "--- Non-array Target Error Path ---"
math.printm("not_an_array")
math.printm(12345)
math.printm(nil)
