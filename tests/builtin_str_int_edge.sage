# Test str() and int() type conversion builtins under normal and edge conditions.
# NOTE: In SVM, str([1, 2]) returns "<array>" representation,
# and int(non-numeric/nil) evaluates to 0.

print "--- str() conversions ---"
print "str(123): " + str(123)
print "str(-45.6): " + str(-45.6)
print "str(true): " + str(true)
print "str(false): " + str(false)
print "str(nil) == 'nil': " + str(str(nil) == "nil")
print "str([1, 2]): " + str([1, 2])

print "--- int() conversions ---"
print "int(123): " + str(int(123))
print "int(45.8): " + str(int(45.8))
print "int(-12.3): " + str(int(-12.3))
print "int('99'): " + str(int("99"))
print "int('-15'): " + str(int("-15"))
print "int('3.14'): " + str(int("3.14"))
print "int('invalid'): " + str(int("invalid"))
print "int(true): " + str(int(true))
print "int(false): " + str(int(false))
print "int(nil): " + str(int(nil))
