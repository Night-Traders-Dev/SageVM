# Test floating-point operations and comparisons edge cases

print "--- Float Arithmetic & Mixed Operations ---"
print "10.5 + 2: " + str(10.5 + 2)
print "10.5 - 2.5: " + str(10.5 - 2.5)
print "2.5 * -4.0: " + str(2.5 * -4.0)
print "7.5 / 2.5: " + str(7.5 / 2.5)
print "10.5 % 3.0: " + str(10.5 % 3.0)

print "--- Float Relational & Equality Comparisons ---"
print "3.14 > 3.0: " + str(3.14 > 3.0)
print "2.5 <= 2.5: " + str(2.5 <= 2.5)
print "2.5 == 2.5: " + str(2.5 == 2.5)
print "-0.5 < 0.0: " + str(-0.5 < 0.0)

print "--- Float Conversions ---"
print "int(3.99): " + str(int(3.99))
print "int(-3.99): " + str(int(-3.99))
print "tonumber('3.14159'): " + str(tonumber("3.14159"))
print "tonumber('-0.5'): " + str(tonumber("-0.5"))

print "--- Division by zero float ---"
print "1.0 / 0.0: " + str(1.0 / 0.0)
