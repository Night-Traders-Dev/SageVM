print "=== Bitwise Operators Edge Cases ==="

let a = 12
let b = 10

print "a & b:"
print a & b

print "a | b:"
print a | b

print "a ^ b:"
print a ^ b

print "~a:"
print ~a

print "~0:"
print ~0

print "a << 2:"
print a << 2

print "a >> 1:"
print a >> 1

print "a & 0:"
print a & 0

print "a | 0:"
print a | 0

print "a ^ 0:"
print a ^ 0

print "a << 0:"
print a << 0

print "a >> 0:"
print a >> 0

print "-1 & 255:"
print -1 & 255

print "Chained bitwise:"
let c = (15 & 7) | (1 << 3)
print c
