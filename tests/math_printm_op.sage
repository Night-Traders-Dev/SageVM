# Test math.printm matrix printing builtin / opcode
import math

print "2D Matrix:"
math.printm([[1, 2], [3, 4]])

print "1D Array:"
math.printm([5, 6, 7])

print "Non-array edge case:"
math.printm("invalid")

print "Nil edge case:"
math.printm(nil)
