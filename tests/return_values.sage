proc explicit_return():
    return "returned value"

proc implicit_return():
    let x = 10
    # No return statement

proc early_return(x):
    if x > 10:
        return "early"
    return "late"

print "Explicit: " + str(explicit_return())
print "Implicit: " + str(implicit_return())
print "Early (15): " + str(early_return(15))
print "Early (5): " + str(early_return(5))
