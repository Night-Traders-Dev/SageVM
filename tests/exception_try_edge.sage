# Test exception handling edge cases (clean try blocks, primitive exceptions, and nested try-catch re-raising array payloads).

print "--- Clean try block ---"
try:
    print "Inside clean try"
catch e:
    print "Should not catch: " + str(e)
print "After clean try"

print "--- Raising primitive values ---"
try:
    raise 404
catch e1:
    print "Caught int: " + str(e1)

try:
    raise false
catch e2:
    print "Caught bool: " + str(e2)

try:
    raise nil
catch e3:
    print "Caught nil == nil: " + str(e3 == nil)

print "--- Nested try with array exception ---"
try:
    try:
        raise ["err", 500]
    catch inner_err:
        print "Inner caught array len: " + str(len(inner_err))
        raise inner_err
catch outer_err:
    print "Outer caught array code: " + str(outer_err[1])
