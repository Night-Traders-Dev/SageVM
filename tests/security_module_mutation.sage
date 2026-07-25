import math

print "math.pi before mutation: " + str(math.pi)

try:
    math.pi = 99.9
    print "mutated math.pi: " + str(math.pi)
catch e:
    print "caught exception mutating math"

print "math.pi after mutation: " + str(math.pi)
