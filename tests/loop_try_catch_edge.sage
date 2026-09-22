# Test try-catch exception handling inside loops and loops inside try-catch blocks

print "--- Catch exception inside loop and continue ---"
var i = 0
while i < 5:
    i = i + 1
    try:
        if i == 3:
            raise "Error at iteration 3"
        print "Normal iteration " + str(i)
    catch err:
        print "Caught in loop: " + str(err)

print "--- Loop inside try-catch with raise ---"
var j = 0
try:
    while j < 5:
        j = j + 1
        print "Loop count " + str(j)
        if j == 3:
            raise "Fatal loop error"
catch err:
    print "Caught outside loop: " + str(err)

print "--- Break inside try block inside loop ---"
var k = 0
while k < 5:
    k = k + 1
    try:
        if k == 3:
            break
        print "Try iteration " + str(k)
    catch err:
        print "Error: " + str(err)
print "Exited loop at k=" + str(k)
