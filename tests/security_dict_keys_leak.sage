import math

# Security Test: Verify dict_values filters out host function handles and nil properties in safe mode
let v = dict_values(math)
# math module contains pi, e, printm (3 valid safe properties)
# in safe_mode, native function handles/nil properties are filtered out from dict_values
print len(v)

let d = {"a": 1, "__secret": 2}
let dk = dict_keys(d)
print len(dk)
print dk[0]
