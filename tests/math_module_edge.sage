# Test math module functions, constants, printm, and edge cases
import math

print "--- Math Constants ---"
print "math.pi > 3.14: " + str(math.pi > 3.14)
print "math.e > 2.71: " + str(math.e > 2.71)

print "--- Math Functions ---"
# BUG: Native math functions (math.abs, math.sqrt, math.sin, math.cos) return nil under SVM when invoked via the module dictionary bridge
print "math.abs(-42): " + str(math.abs(-42))
print "math.abs(0): " + str(math.abs(0))
print "math.sqrt(100): " + str(math.sqrt(100))
print "math.sqrt(0): " + str(math.sqrt(0))
print "math.sin(0): " + str(math.sin(0))
print "math.cos(0): " + str(math.cos(0))

print "--- Math Print Matrix ---"
math.printm([[1, 2], [3, 4]])

print "--- Edge Cases / Error Paths ---"
print "math.sqrt(-1) == nil: " + str(math.sqrt(-1) == nil)
print "math.abs(nil) == nil: " + str(math.abs(nil) == nil)
print "non-array printm:"
math.printm(123)
