proc run_nested(max_i, max_j):
    var i = 0
    while i < max_i:
        var j = 0
        while j < max_j:
            print "i=" + str(i) + " j=" + str(j)
            j = j + 1
        i = i + 1

print "=== Test 1: Function Scope Nested Loops ==="
run_nested(2, 2)

print "=== Test 2: Global Variable Scope Loop ==="
var g = 0
while g < 3:
    print "g=" + str(g)
    g = g + 1

print "=== Test 3: Zero Iterations Inner Loop ==="
var outer_count = 0
var inner_count = 0
var x = 0
while x < 2:
    outer_count = outer_count + 1
    var y = 5
    while y < 3:
        inner_count = inner_count + 1
        y = y + 1
    x = x + 1
print "outer=" + str(outer_count) + " inner=" + str(inner_count)
