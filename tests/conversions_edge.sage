# Test conversion builtins (int, tonumber, str) edge cases

print "1. Whitespace conformance in conversions:"
print int("   123   ")
print tonumber("   456.78   ")

print "2. Empty string conversions:"
print int("")
print tonumber("") == nil

print "3. Conversions of other types (boolean, nil, collections):"
print int(true)
print int(false)
print int(nil)

print tonumber(true) == nil
print tonumber(false) == nil
print tonumber(nil) == nil

print "4. str() on nested collections and nil:"
print str([1, [2, 3], {"a": nil}])
print str(nil)
