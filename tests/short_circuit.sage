proc side_effect(val):
    print "Side effect: " + str(val)
    return val

print "--- OR ---"
print true or side_effect(true)
print false or side_effect(true)
print false or side_effect(false)

print "--- AND ---"
print false and side_effect(false)
print true and side_effect(true)
print true and side_effect(false)
