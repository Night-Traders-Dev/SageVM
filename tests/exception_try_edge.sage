# Test try-catch exception handling, raising non-string primitives, and nested try blocks.

print "--- Clean try block execution ---"
try:
    print "Inside clean try"
catch err:
    print "Caught error: " + str(err)
print "After clean try"

print "--- Raising primitive values ---"
try:
    raise 404
catch err:
    print "Caught number exception: " + str(err)

try:
    raise false
catch err:
    print "Caught bool exception: " + str(err)

try:
    raise nil
catch err:
    print "Caught nil exception: " + str(err)

print "--- Nested try-catch blocks ---"
try:
    print "Outer try start"
    try:
        print "Inner try start"
        raise ["nested_error", 100]
    catch inner_err:
        print "Inner catch: " + str(inner_err)
        raise inner_err
catch outer_err:
    print "Outer catch: " + str(outer_err)

print "--- Done exception tests ---"
