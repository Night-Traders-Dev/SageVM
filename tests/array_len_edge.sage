# Test len() (OP_ARRAY_LEN) edge cases
print "Empty array:"
print len([])

print "Empty dict:"
print len({})

print "String length:"
print len("hello")
print len("")

# Edge case: len(nil) - should return 0 or error?
# In SageLang host, len(nil) might throw an error or return 0.
# Let's see what SVM does.
print "len(nil):"
print len(nil)
