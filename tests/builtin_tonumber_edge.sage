# Test tonumber(), str(), int() builtins edge cases
print "--- tonumber built-in ---"
print tonumber("123")
print tonumber("45.67")
print tonumber("invalid")
print tonumber(nil)
print tonumber(true)
print tonumber(42)

print "--- str built-in ---"
print str(100)
print str(nil)
print str(true)
print str([1, 2])

print "--- int built-in ---"
print int(12.34)
print int("56")
print int(nil)
