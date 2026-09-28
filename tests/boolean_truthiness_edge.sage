print "=== Truthiness Edge Cases ==="

proc check_bool(val):
    if val:
        print "truthy"
    else:
        print "falsy"

print "booleans:"
check_bool(true)
check_bool(false)

print "nil:"
check_bool(nil)

print "numbers:"
check_bool(0)
check_bool(1)
check_bool(-42)
check_bool(0.0)
check_bool(3.14)

print "strings:"
check_bool("")
check_bool("hello")

print "collections:"
check_bool([])
check_bool([1, 2])
check_bool({})
check_bool({"a": 1})

print "not operators:"
print not true
print not false
print not nil
print not 0
print not 1
print not ""
print not "ok"

print "double negation:"
print not not true
print not not false
print not not nil
print not not 0
print not not 100
print not not "text"
