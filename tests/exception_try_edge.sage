# Test try-catch blocks with clean execution, raising primitive values, and re-raising array exceptions (OP_SETUP_TRY, OP_END_TRY, OP_RAISE)

print "--- Try without exception ---"
var x = 100
try:
    x = 200
    print "Clean execution: " + str(x)
catch e:
    print "Should not reach here"

print "--- Catch primitive values ---"
try:
    raise 404
catch e:
    print "Caught code: " + str(e)

try:
    raise false
catch e:
    print "Caught bool: " + str(e)

try:
    raise nil
catch e:
    print "Caught nil: " + str(e == nil)

print "--- Nested try and re-raise ---"
try:
    try:
        raise ["error", "nested"]
    catch err:
        print "Inner caught array len: " + str(len(err))
        raise err
catch outer_err:
    print "Outer caught re-raised: " + outer_err[0]
