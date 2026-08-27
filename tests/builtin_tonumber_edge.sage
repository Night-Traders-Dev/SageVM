print "--- tonumber builtin edge cases ---"
print tonumber("123")
print tonumber("-45.67")
print tonumber("0")
print tonumber("invalid")
print tonumber("")
print tonumber(nil)
print tonumber(42)

print "--- str and int builtins ---"
print str(100)
print str(true)
print str(nil)
print str([1, 2])
print int(55.9)
print int("99")
print int(nil)
print int("abc")
