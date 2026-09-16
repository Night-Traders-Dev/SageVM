# Test nested try-catch blocks, non-string error payloads, and catch block re-raising.

print "--- Primitive Exception Payload Types ---"
try:
    raise 500
catch e:
    print "Caught int exception: " + str(e)

try:
    raise false
catch e:
    print "Caught bool exception: " + str(e)

try:
    raise nil
catch e:
    print "Caught nil exception: " + str(e == nil)

print "--- Clean Try Execution (No Exception) ---"
try:
    print "Inside try without raise"
catch e:
    print "Should not catch anything: " + str(e)
print "After clean try"

print "--- Exception Thrown In Catch Block ---"
try:
    try:
        raise "Initial error"
    catch e1:
        print "First catch: " + str(e1)
        raise "Secondary error inside catch"
catch e2:
    print "Second catch: " + str(e2)

print "--- Function Returning From Try ---"
proc test_return_in_try():
    try:
        print "Inside func try"
        return "returned_val"
    catch e:
        print "Caught in func: " + str(e)
    return "default_val"

print "Func return value: " + test_return_in_try()
