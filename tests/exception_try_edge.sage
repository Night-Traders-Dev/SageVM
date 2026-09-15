# Test try-catch edge cases (OP_SETUP_TRY, OP_END_TRY, OP_RAISE)
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
