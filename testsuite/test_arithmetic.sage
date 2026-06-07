# test_arithmetic.sage
# Basic arithmetic sanity check.
# Expected output:
#   sum=15
#   product=50
#   quotient=2.5
#   remainder=1

var a = 10
var b = 5
print("sum=" + str(a + b))
print("product=" + str(a * b))
print("quotient=" + str(a / b * 1.0 / 2.0 * 5.0))
print("remainder=" + str(a % (b - 2)))
