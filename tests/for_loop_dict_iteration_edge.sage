print "--- Dict Key / Value Iteration ---"
var d = {"alpha": 10, "beta": 20, "gamma": 30}
var keys = dict_keys(d)
var vals = dict_values(d)
print "keys count: " + str(len(keys))
print "vals count: " + str(len(vals))

var sum = 0
var i = 0
while i < len(keys):
    let k = keys[i]
    print k + " -> " + str(d[k])
    sum = sum + d[k]
    i = i + 1
print "sum: " + str(sum)

print "--- Value Mutation in Dict ---"
d["alpha"] = 100
d["delta"] = 40
print "alpha after mutation: " + str(d["alpha"])
print "delta added: " + str(d["delta"])
print "dict_has delta: " + str(dict_has(d, "delta"))

print "--- Empty Dict Iteration ---"
var empty_d = {}
var empty_keys = dict_keys(empty_d)
print "empty keys count: " + str(len(empty_keys))
var empty_sum = 0
var j = 0
while j < len(empty_keys):
    empty_sum = empty_sum + 1
    j = j + 1
print "empty loop executed iterations: " + str(empty_sum)

print "--- Non-String / Primitive Keys ---"
var int_key_dict = {}
int_key_dict[1] = "one"
int_key_dict[2] = "two"
print "int key 1: " + str(int_key_dict[1])
print "int key 2: " + str(int_key_dict[2])
print "missing key 3: " + str(int_key_dict[3])
