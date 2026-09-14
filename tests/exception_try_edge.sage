# Test exception handling (OP_SETUP_TRY, OP_END_TRY, OP_RAISE) with clean execution, primitive value raising, and re-raising.

print "--- Clean Try Execution ---"
var val = 100
try:
    print "Clean execution val: " + str(val)
catch e:
    print "Should not print this: " + str(e)

print "--- Primitive Exceptions ---"
try:
    raise 404
catch e:
    print "Caught int: " + str(e)

try:
    raise false
catch e:
    print "Caught bool: " + str(e)

try:
    raise nil
catch e:
    print "Caught nil: " + str(e)

print "--- Nested Re-raising Array Exception ---"
try:
    try:
        raise [10, 20, 30]
    catch inner:
        print "Inner caught len: " + str(len(inner))
        raise inner
catch outer:
    print "Outer caught len: " + str(len(outer))
