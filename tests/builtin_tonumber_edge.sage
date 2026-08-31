# Test tonumber(), str(), and int() builtins across types and edge cases.

print "--- tonumber() conversions ---"
print tonumber("123")
print tonumber("45.67")
print tonumber("-89")
print tonumber(42)
print tonumber(nil) == nil
print tonumber("invalid_str") == nil
print tonumber([1, 2]) == nil

print "--- str() conversions ---"
print str(100)
print str(3.14)
print str(true)
print str(false)
print str(nil)

print "--- int() conversions ---"
print int(123.89)
print int("-45.2")
print int(nil)
print int("non_numeric")
print int(true)
