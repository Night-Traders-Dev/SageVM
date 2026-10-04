# Test chained assignment expressions and operand stack duplicate manipulation (OP_DUP) across variables, collections, and properties

print "--- Chained variable assignments ---"
var a = 0
var b = 0
var c = 0
a = b = c = 100
print "a: " + str(a)
print "b: " + str(b)
print "c: " + str(c)

print "--- Chained variable assignment with arithmetic expression ---"
a = b = 10 + 5 * 2
print "a after expr: " + str(a)
print "b after expr: " + str(b)

print "--- Chained variable assignment with nil ---"
a = b = c = nil
print "a == nil: " + str(a == nil)
print "b == nil: " + str(b == nil)
print "c == nil: " + str(c == nil)

print "--- Chained array index assignments ---"
var arr = [0, 0, 0]
arr[0] = arr[1] = arr[2] = 77
print "arr[0]: " + str(arr[0])
print "arr[1]: " + str(arr[1])
print "arr[2]: " + str(arr[2])

print "--- Chained dictionary key assignments ---"
var dict_obj = {}
dict_obj["k1"] = dict_obj["k2"] = "shared_value"
print "dict_obj['k1']: " + str(dict_obj["k1"])
print "dict_obj['k2']: " + str(dict_obj["k2"])

print "--- Chained object property assignments ---"
class Target:
    proc init(self):
        self.p1 = 0
        self.p2 = 0

var obj = Target()
obj.p1 = obj.p2 = 9.99
print "obj.p1: " + str(obj.p1)
print "obj.p2: " + str(obj.p2)
