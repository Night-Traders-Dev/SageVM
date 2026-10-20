# Test dictionary key/value iteration, loop updates, empty dicts, non-string keys, and dict_has containment.

print "--- Loop iteration over dict keys ---"
var d1 = {"a": 10, "b": 20, "c": 30}
var keys1 = dict_keys(d1)
var k_idx = 0
var sum1 = 0
while k_idx < len(keys1):
    var k = keys1[k_idx]
    sum1 = sum1 + d1[k]
    k_idx = k_idx + 1
print "Sum of values: " + str(sum1)

print "--- Loop iteration over dict values ---"
var vals1 = dict_values(d1)
var v_idx = 0
var v_sum = 0
while v_idx < len(vals1):
    v_sum = v_sum + vals1[v_idx]
    v_idx = v_idx + 1
print "Vals count: " + str(len(vals1))
print "Vals sum: " + str(v_sum)

print "--- Dict mutation inside loop ---"
var d2 = {"x": 1, "y": 2, "z": 3}
var keys2 = dict_keys(d2)
var i = 0
while i < len(keys2):
    var key = keys2[i]
    d2[key] = d2[key] * 10
    i = i + 1

print "d2['x']: " + str(d2["x"])
print "d2['y']: " + str(d2["y"])
print "d2['z']: " + str(d2["z"])

print "--- Empty dictionary iteration ---"
var emp_d = {}
var emp_k = dict_keys(emp_d)
print "Empty keys len: " + str(len(emp_k))
var emp_v = dict_values(emp_d)
print "Empty vals len: " + str(len(emp_v))

print "--- Non-string key containment and lookup ---"
var d3 = {}
d3[100] = "century"
d3[true] = "flag"
print "dict_has 100: " + str(dict_has(d3, 100))
print "d3[100]: " + str(d3[100])
print "dict_has true: " + str(dict_has(d3, true))
print "d3[true]: " + str(d3[true])
print "dict_has missing: " + str(dict_has(d3, "missing"))
print "d3['missing'] == nil: " + str(d3["missing"] == nil)
