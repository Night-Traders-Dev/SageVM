# Test for-loop iteration behavior across various collection types and boundary inputs

print "--- Array Iteration ---"
var nums = [10, 20, 30]
for n in nums:
    print n

print "--- Nested Array Iteration ---"
var matrix = [[1, 2], [3, 4]]
for row in matrix:
    print row[0]
    print row[1]

print "--- String Character Iteration ---"
var word = "abc"
for ch in word:
    print ch

print "--- Empty Array Iteration ---"
for x in []:
    print "should not execute"
print "empty array done"

print "--- Empty String Iteration ---"
for c in "":
    print "should not execute"
print "empty string done"

print "--- Nil Iteration Safety ---"
for item in nil:
    print "should not execute"
print "nil iteration done"
