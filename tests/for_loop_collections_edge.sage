print "=== For Loop over Array ==="
var arr = [10, 20, 30]
var sum = 0
for x in arr:
    print x
    sum = sum + x
print "sum:"
print sum

print "=== For Loop over Nested Array ==="
var matrix = [[1, 2], [3, 4]]
for row in matrix:
    for item in row:
        print item

print "=== For Loop over Empty Array ==="
var empty_arr = []
for e in empty_arr:
    print "unreachable"
print "empty array loop done"

print "=== For Loop over String ==="
var word = "Sage"
for char in word:
    print char

print "=== For Loop over Empty String ==="
for c in "":
    print "unreachable"
print "empty string loop done"

print "=== For Loop over Nil ==="
for n in nil:
    print "unreachable"
print "nil loop done"
