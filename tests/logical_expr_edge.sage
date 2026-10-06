print "--- Logical Expression Chaining ---"
var t = true
var f = false

var r1 = (t and f) or t
print "r1:"
print r1

var r2 = (f or f) and t
print "r2:"
print r2

var r3 = not (t and not f)
print "r3:"
print r3

print "--- Non-Boolean Truthiness in Conditionals ---"
if 0:
    print "0 is truthy"
else:
    print "0 is falsy"

if 100:
    print "100 is truthy"

if "":
    print "empty string is truthy"
else:
    print "empty string is falsy"

if "sage":
    print "non-empty string is truthy"

if nil:
    print "nil is truthy"
else:
    print "nil is falsy"

if []:
    print "empty array is truthy"

if {}:
    print "empty dict is truthy"

print "--- Logical Short-Circuit Value Returns ---"
proc side_effect():
    print "Side effect triggered!"
    return true

print "Short-circuit OR (true or side_effect):"
if true or side_effect():
    print "OR passed"

print "Short-circuit AND (false and side_effect):"
if false and side_effect():
    print "AND failed"
else:
    print "AND short-circuited"
