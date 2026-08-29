# Test chr() and ord() builtins edge cases
print "--- chr basic and edge cases ---"
print chr(65)
print chr(97)
print chr(48)
print chr(32) == " "
print chr(nil)
print chr("A")

print "--- ord basic and edge cases ---"
print ord("A")
print ord("a")
print ord("0")
print ord("")
print ord(nil)
print ord(123)
