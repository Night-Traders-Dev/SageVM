# Test exception handling edge cases: try-catch with no exception raised, raising non-string values, and re-raising across blocks

print "--- Try block with no exceptions ---"
var status = "OK"
try:
    print "Inside clean try, status = " + str(status)
catch e:
    print "Should not enter catch: " + str(e)
print "After clean try block"

print "--- Raising primitive values ---"
try:
    raise 404
catch e1:
    print "Caught int exception: " + str(e1)

try:
    raise false
catch e2:
    print "Caught bool exception: " + str(e2)

try:
    raise nil
catch e3:
    print "Caught nil exception: " + str(e3)

print "--- Nested try re-raise with array ---"
try:
    try:
        raise ["ERR_CODE", 101]
    catch inner_e:
        print "Inner caught array: " + str(inner_e)
        raise inner_e
catch outer_e:
    print "Outer caught re-raised: " + str(outer_e)
