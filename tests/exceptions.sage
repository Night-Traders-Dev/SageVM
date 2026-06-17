# Test exception handling (OP_SETUP_TRY, OP_END_TRY, OP_RAISE)
print "Start try"
try:
    print "Inside try"
    raise "Error value"
    print "After raise (should not see this)"
catch e:
    print "Caught exception: " + str(e)
print "End try"

# Test nested exception handlers
print "Start nested"
try:
    try:
        raise "Nested error"
    catch e1:
        print "Caught nested: " + str(e1)
        raise "Re-raised error"
catch e2:
    print "Caught re-raised: " + str(e2)
print "End nested"
