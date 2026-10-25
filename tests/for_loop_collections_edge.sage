print "--- For loop over nested array ---"
var matrix = [[10, 20], [30, 40]]
for row in matrix:
    for item in row:
        print item

print "--- For loop over string ---"
for ch in "SageVM":
    print ch

print "--- For loop over empty array ---"
for x in []:
    print "should not print"
print "empty array done"

print "--- For loop over empty string ---"
for s in "":
    print "should not print"
print "empty string done"

print "--- For loop over nil ---"
for n in nil:
    print "should not print"
print "nil done"