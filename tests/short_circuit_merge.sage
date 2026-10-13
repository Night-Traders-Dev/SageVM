print "--- Short-Circuit Result Value ---"
# The two arms of `and` / `or` meet at one continuation, each having put its
# result in a register it allocated itself. Reading the other arm's register
# is what made `true and false` print 0.

print true and false
print true or false
print false and true
print false or true
print true and true
print false or false

print "--- Truthiness, Not Identity ---"
# `and` / `or` yield a bool here, not the operand that decided the result.
print 0 or "fallback"
print "value" and "second"
print nil or 7
print [] or "empty"

print "--- Result Survives The Continuation ---"
# The merge register has to feed what comes after the join, not just a print.
var a = true and false
print a
print a or true
print not (true and false)
print (true or false) and (false or true)

print "--- Nested Short-Circuit ---"
print true and (false or true)
print (false and true) or (true and false)
print true and false and true
print true or false or false

print "--- Inside Control Flow ---"
if true and false:
    print "unreachable"
else:
    print "else taken"
if false or true:
    print "then taken"
var n = 0
while n < 3:
    if n == 1 or n == 2:
        print n
    n = n + 1