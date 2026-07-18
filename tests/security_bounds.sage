# Test standard local variable and duplicate expressions under safe mode to verify bounds protection
var x = 10
var y = 20
var z = (x + y) * (x - y)
print "Result: " + str(z)
