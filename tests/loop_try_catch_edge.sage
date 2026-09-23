print "=== Test 1: Exception Inside Loop Body ==="
var i = 0
while i < 4:
    try:
        if i == 2:
            raise "error at iteration 2"
        print "iter " + str(i) + " ok"
    catch err:
        print "caught in loop: " + str(err)
    i = i + 1

proc test_seq_loop():
    var count1 = 0
    try:
        var j = 0
        while j < 3:
            count1 = count1 + 1
            j = j + 1
        print "loop 1 completed count=" + str(count1)
        raise "trigger catch"
    catch err:
        print "caught: " + str(err)

    var count2 = 0
    var k = 0
    while k < 3:
        count2 = count2 + 1
        k = k + 1
    print "loop 2 completed count=" + str(count2)

print "=== Test 2: Exception Handling in Sequential Loops ==="
test_seq_loop()

proc test_nested_catch():
    var x = 0
    while x < 2:
        var y = 0
        while y < 2:
            try:
                if x == 1 and y == 0:
                    raise "nested fail"
                print "x=" + str(x) + " y=" + str(y)
            catch err:
                print "caught nested: " + str(err)
            y = y + 1
        x = x + 1

print "=== Test 3: Exception Thrown and Caught in Nested Loop ==="
test_nested_catch()
