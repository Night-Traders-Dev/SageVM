# Test string concatenation edge cases

print "1. Concatenation with nil:"
print "hello" + nil
print nil + "world"

print "2. Concatenation with empty string:"
print "hello" + ""
print "" + "world"

print "3. Concatenation with non-string types:"
print "value: " + 123
print "value: " + true
print "value: " + false

print "4. Multiple concatenations:"
print "a" + "b" + "c" + "d"
