# Test contains() builtin
# Documented in SPEC.md but missing in SVM interpreter.

let res1 = contains([1, 2, 3], 2)
print "Array contains 2: " + str(res1)
let res2 = contains("hello", "e")
print "String contains 'e': " + str(res2)
