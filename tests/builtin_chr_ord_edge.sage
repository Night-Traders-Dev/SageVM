# Test chr() and ord() builtins across boundary values and edge cases.

print "--- Standard ASCII ---"
print chr(65)
print chr(97)
print chr(48)
print ord("A")
print ord("a")
print ord("0")

print "--- Boundary Values ---"
print ord(chr(0))
print ord(chr(127))

print "--- Edge Cases: Empty strings and nil ---"
print chr(nil) == ""
print ord("")
print ord(nil)

print "--- Edge Cases: Non-string and Non-number Inputs ---"
print ord(123)
print chr("65")
