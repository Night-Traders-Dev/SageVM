# Test truthiness evaluation (OP_TRUTHY, OP_NOT, OP_JUMP_IF_FALSE)
# across booleans, nil, numbers, strings, arrays, dictionaries, and double negation.

print "--- Boolean Truthiness & Logical NOT ---"
print not true
print not false
print not nil

print "--- Truthiness in Conditional Jumps ---"
if true:
    print "true condition"

if false:
    print "false condition"

if nil:
    print "nil condition"
else:
    print "nil evaluated false"

if 0:
    print "zero condition"
else:
    print "zero evaluated false"

if -1:
    print "negative integer evaluated true"

if 3.14:
    print "float evaluated true"

if "":
    print "empty string evaluated true"
else:
    print "empty string evaluated false"

if "hello":
    print "non-empty string evaluated true"

if []:
    print "empty array evaluated true"

if {"a": 1}:
    print "dictionary evaluated true"

print "--- Double Negation ---"
print not (not true)
print not (not false)
print not (not nil)
print not (not 0)
print not (not "text")
