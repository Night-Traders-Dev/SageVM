proc side_effect(val, msg):
    print msg
    return val

print "Testing OR short-circuit:"
# Should NOT print "OR FAIL"
if true or side_effect(true, "OR FAIL"):
    print "OR 1 OK"

# SHOULD print "OR PASS"
if false or side_effect(true, "OR PASS"):
    print "OR 2 OK"

print "Testing AND short-circuit:"
# Should NOT print "AND FAIL"
if false and side_effect(false, "AND FAIL"):
    print "AND 1 FAIL"
else:
    print "AND 1 OK"

# SHOULD print "AND PASS"
if true and side_effect(false, "AND PASS"):
    print "AND 2 FAIL"
else:
    print "AND 2 OK"
proc side_effect(val):
    print "Side effect: " + str(val)
    return val

print "--- OR ---"
print true or side_effect(true)
print false or side_effect(true)
print false or side_effect(false)

print "--- AND ---"
print false and side_effect(false)
print true and side_effect(true)
print true and side_effect(false)
