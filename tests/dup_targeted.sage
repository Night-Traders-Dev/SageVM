# Test OP_DUP in more complex scenarios
# Multiple assignment is the primary user of OP_DUP in SageLang

var a = 1
var b = 2
var c = 3

# a = (b = (c = 10))
a = b = c = 10
print a
print b
print c

# Verify that the value remains on the stack and can be used in an expression
# (This depends on how SageLang compiles it, but usually a = b = 10 results in 10 on stack)
var d = 0
d = (a = 20) + 5
print a
print d

# Nested multiple assignments
var x = 0
var y = 0
var z = 0
x = (y = 30) + (z = 40)
print x
print y
print z
