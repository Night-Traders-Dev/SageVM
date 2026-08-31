# Test range() and clock() builtins across normal execution and edge cases.

print "--- Range Standard Positive ---"
let r1 = range(5)
print len(r1)
print r1[0]
print r1[4]

print "--- Range Zero and Negative ---"
let r0 = range(0)
print len(r0)
let rneg = range(-5)
print len(rneg)

print "--- Range Invalid / Nil Inputs ---"
let rnil = range(nil)
print len(rnil)
let rstr = range("3")
print len(rstr)
print rstr[0]

print "--- Clock Builtin Sanity ---"
let t = clock()
print type(t) == "number" or t >= 0
