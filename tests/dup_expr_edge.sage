# Test OP_DUP and stack manipulation across multi-variable chained assignments and expressions

print "--- Simple Chained Assignment ---"
var a = 0
var b = 0
var c = 0
a = b = c = 50
print "a: " + str(a)
print "b: " + str(b)
print "c: " + str(c)

print "--- Chained Nil Assignment ---"
var x = 1
var y = 2
x = y = nil
print "x == nil: " + str(x == nil)
print "y == nil: " + str(y == nil)

print "--- Expression Assignment Stacking ---"
var p = 0
var q = 0
var sum = (p = 15) + (q = 25)
print "p: " + str(p)
print "q: " + str(q)
print "sum: " + str(sum)

print "--- Chained Array & Property Assignments ---"
var arr = [0, 0]
var d = {}
arr[0] = d["key"] = 99
print "arr[0]: " + str(arr[0])
print "d.key: " + str(d.key)

print "--- Chained Reassignment in Loop ---"
var i = 0
var total = 0
while i < 3:
    var k = 0
    total = total + (k = i * 10)
    i = i + 1
print "total: " + str(total)
