import math

print "--- Math module constants ---"
print "math.pi > 3.14: " + str(math.pi > 3.14)
print "math.e > 2.71: " + str(math.e > 2.71)

print "--- Math module native functions ---"
# Note/Conformance gap: Direct invocation of native math function bridge
# (math.abs, math.sqrt, math.sin, math.cos) returns nil under SVM
print "math.abs(-10): " + str(math.abs(-10))
print "math.sqrt(16): " + str(math.sqrt(16))
print "math.sin(0): " + str(math.sin(0))
print "math.cos(0): " + str(math.cos(0))

print "--- Math module functions with nil/invalid args ---"
print "math.abs(nil): " + str(math.abs(nil))
print "math.sqrt(nil): " + str(math.sqrt(nil))
