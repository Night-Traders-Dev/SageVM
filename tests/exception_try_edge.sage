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
