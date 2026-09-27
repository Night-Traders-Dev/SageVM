# Test short-circuit evaluation, side-effects, and non-boolean truthiness edge cases

proc tracker(val, tag):
    print "tracker called: " + tag
    return val

print "--- OR Short-Circuit Evaluation ---"
print "Left true -> Right NOT called:"
if true or tracker(true, "OR_SKIP"):
    print "Branch 1 taken"

print "Left false -> Right called:"
if false or tracker(true, "OR_RUN"):
    print "Branch 2 taken"

print "--- AND Short-Circuit Evaluation ---"
print "Left false -> Right NOT called:"
if false and tracker(true, "AND_SKIP"):
    print "Branch 3 taken"
else:
    print "Branch 3 skipped"

print "Left true -> Right called:"
if true and tracker(true, "AND_RUN"):
    print "Branch 4 taken"

print "--- Truthiness in Short-Circuit Expressions ---"
print "Non-empty string in OR:"
if "hello" or tracker(false, "STR_OR_SKIP"):
    print "String truthy OK"

print "Nil in OR:"
if nil or tracker(true, "NIL_OR_RUN"):
    print "Nil falsy OK"

print "Zero in OR:"
if 0 or tracker(true, "ZERO_OR_RUN"):
    print "Zero truthy/falsy check OK"

print "--- Chained Logical Expressions ---"
if tracker(false, "C1") or tracker(false, "C2") or tracker(true, "C3") or tracker(true, "C4_SKIP"):
    print "Chained OR resolved"

if tracker(true, "A1") and tracker(true, "A2") and tracker(false, "A3") and tracker(true, "A4_SKIP"):
    print "Chained AND resolved taken"
else:
    print "Chained AND resolved stopped at A3"
