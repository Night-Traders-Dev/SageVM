import math

# Verify push/pop modification protection in safe mode
try:
    push(math, 42)
catch e:
    print "Caught exception or push blocked"

try:
    pop(math)
catch e:
    print "Caught exception or pop blocked"

# Verify dict_has does not expose internal keys starting with __ in safe mode
let has_host = dict_has(math, "__host_mod__")
print "dict_has internal: " + str(has_host)

# Verify dict_keys filters out internal keys in safe mode
let keys = dict_keys(math)
var has_internal_key = false
var i = 0
while i < len(keys):
    let k = keys[i]
    if type(k) == "string" and startswith(k, "__"):
        has_internal_key = true
    i = i + 1
print "dict_keys contains internal key: " + str(has_internal_key)

# Verify dict_values filters out internal values in safe mode
let values = dict_values(math)
var has_internal_val = false
# In math module, we have keys like pi, e, abs, sqrt, sin, cos, printm, and __type__
# In safe mode, __type__ value must be filtered out
var j = 0
while j < len(values):
    let v = values[j]
    if type(v) == "string" and (v == "module" or startswith(v, "__")):
        has_internal_val = true
    j = j + 1
print "dict_values contains internal value: " + str(has_internal_val)
