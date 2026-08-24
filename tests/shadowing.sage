# Variable shadowing

var x = "global"

proc test_shadow(x):
    print x # Should be "param"
    var x = "local"
    print x # Should be "local"

print x # Should be "global"
test_shadow("param")
print x # Should be "global"

proc test_no_shadow():
    var x = "inner"
    print x # Should be "inner"

test_no_shadow()
print x # Should be "global"
