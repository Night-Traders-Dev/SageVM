# Test range() and clock() builtins edge cases
print "--- range basic ---"
let r1 = range(5)
print len(r1)
print r1[0]
print r1[4]

print "--- range zero / negative ---"
let r2 = range(0)
print len(r2)
let r3 = range(-5)
print len(r3)

print "--- range invalid / nil ---"
print range(nil)
print range("invalid")

print "--- clock test ---"
let c = clock()
print type(c)
