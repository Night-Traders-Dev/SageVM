# Test bracket character indexing on strings
let s = "hello"
print "String length:"
print len(s)

print "String indexing [0]:"
print s[0]

print "String indexing [1]:"
print s[1]

print "String indexing [4]:"
print s[4]

print "String indexing out of bounds (positive):"
# In SageLang, indexing out of bounds on string evaluates to nil. Let's verify.
print s[5]

print "String indexing out of bounds (negative):"
print s[-6]
