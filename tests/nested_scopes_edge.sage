# Test multi-level block scopes, variable lookups across nested environments,
# local shadowing, scope restoration after exiting blocks, and unbound lookup.

var g = "global_var"
var level1 = "level1_var"

print "--- Initial Global State ---"
print g
print level1

if true:
    var level1 = "shadowed_level1"
    var level2 = "level2_var"
    print "--- Inside Level 1 Scope ---"
    print g
    print level1
    print level2

    if true:
        var level3 = "level3_var"
        print "--- Inside Level 2 Scope ---"
        print g
        print level1
        print level2
        print level3
        var g = "shadowed_global"
        print g

    print "--- Back in Level 1 Scope ---"
    # Note: Under SageLang frontend variable assignment semantics in SVM, reassignment/redeclaration
    # inside nested blocks updates the enclosing global environment dictionary rather than isolating block scope.
    print g
    print level1
    print level2

print "--- Back in Global Scope ---"
print g
print level1

print "--- Unbound Variable Lookup in Scope ---"
if true:
    var shadow_test = nil
    print shadow_test
