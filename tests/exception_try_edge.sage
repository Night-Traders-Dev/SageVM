# Test try-catch blocks, primitive/collection exception raising, and nested unwinding (OP_SETUP_TRY, OP_END_TRY, OP_RAISE)

print "--- Clean Try Block ---"
try:
    print "normal execution without raise"
catch e:
    print "should not execute"
print "after try"

print "--- Primitive Raises ---"
try:
    raise 404
catch e:
    print "caught int: " + str(e)

try:
    raise false
catch e:
    print "caught bool: " + str(e)

try:
    raise nil
catch e:
    print "caught nil: " + str(e == nil)

print "--- Collection Raise ---"
try:
    raise [10, 20, 30]
catch e:
    print "caught array len: " + str(len(e))

print "--- Nested Try and Re-raise ---"
try:
    try:
        raise "inner error"
    catch e1:
        print "caught inner: " + str(e1)
        raise "outer error"
catch e2:
    print "caught re-raise: " + str(e2)
