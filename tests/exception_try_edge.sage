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

# Covers clean try completion, raising primitive values (int, bool, nil, array),
# and re-raising across nested try blocks.

print "--- Clean try block completion ---"
try:
    print "Inside clean try block"
catch e:
    print "Should not catch anything: " + str(e)
print "After clean try block"

print "--- Raising primitive values ---"
try:
    raise 404
catch err_code:
    print "Caught integer exception: " + str(err_code)

try:
    raise false
catch err_bool:
    print "Caught boolean exception: " + str(err_bool)

try:
    raise nil
catch err_nil:
    print "Caught nil exception: " + str(err_nil == nil)

print "--- Raising structured array exception ---"
try:
    raise ["ERR_OOB", 101, "Index out of range"]
catch err_arr:
    print "Caught array exception code: " + str(err_arr[0]) + " id: " + str(err_arr[1]) + " msg: " + str(err_arr[2])

print "--- Re-raising primitive across nested try blocks ---"
try:
    try:
        raise 99
    catch inner:
        print "Inner catch got: " + str(inner)
        raise inner
catch outer:
    print "Outer catch got re-raised: " + str(outer)
print "Done exception edge tests"
