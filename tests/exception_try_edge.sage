# Test try-catch exception handling edge cases: clean execution, non-string exception payloads, and nested re-raising.

print "--- Clean Try Block Execution ---"
try:
    print "Inside clean try block"
    print "Computed sum: 30"
catch e:
    print "Unexpected catch: " + str(e)
print "After clean try block"

print "--- Raising Primitive Values ---"
try:
    raise 404
catch e:
    print "Caught integer exception: " + str(e) + ", type: " + type(e)

try:
    raise false
catch e:
    print "Caught boolean exception: " + str(e) + ", type: " + type(e)

try:
    raise nil
catch e:
    print "Caught nil exception: " + str(e == nil)

print "--- Raising Array Exceptions ---"
try:
    raise [500, "Server Error"]
catch e:
    print "Caught array exception, len: " + str(len(e)) + ", code: " + str(e[0]) + ", msg: " + str(e[1])

print "--- Nested Re-raising Across Blocks ---"
try:
    print "Outer try start"
    try:
        print "Inner try start"
        raise "Initial error"
    catch err1:
        print "Inner caught: " + str(err1)
        raise "Reraised error: " + str(err1)
catch err2:
    print "Outer caught: " + str(err2)
print "Outer try end"
