# Test nested loops with break and continue control flow opcodes (OP_LOOP_BACK, OP_BREAK, OP_CONTINUE)

print "--- Nested while loops with inner break ---"
var i = 0
var j = 0
while i < 3:
    j = 0
    print "Outer i=" + str(i)
    while j < 5:
        if j == 2:
            break
        print "  Inner j=" + str(j)
        j = j + 1
    i = i + 1

print "--- Nested while loops with inner continue ---"
var m = 0
var n = 0
while m < 2:
    n = 0
    print "Outer m=" + str(m)
    while n < 4:
        n = n + 1
        if n == 2:
            continue
        print "  Inner n=" + str(n)
    m = m + 1

print "--- Break outer loop from inner condition ---"
var x = 0
var y = 0
var stop_all = false
while x < 3:
    y = 0
    while y < 3:
        if x == 1 and y == 1:
            stop_all = true
            break
        print "x=" + str(x) + ", y=" + str(y)
        y = y + 1
    if stop_all:
        break
    x = x + 1
