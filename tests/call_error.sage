print "Testing invalid call:"
var x = 10
# BUG: Calling a non-callable object should raise an exception.
# Currently, it only prints an error message to stdout and does NOT raise.
try:
    x()
    # print "After call"
catch e:
    print "Caught: " + str(e)
