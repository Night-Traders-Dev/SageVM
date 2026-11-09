import math

# Security Test: Verify reflection on protected host modules returns nothing under safe mode.
let vals = dict_values(math)
# math is a protected host module; dict_keys/dict_values expose no metadata for it.
print len(vals)

let d = {"visible": 10, "__internal": 20}
let safe_keys = dict_keys(d)
let safe_vals = dict_values(d)
print safe_keys[0]
print safe_vals[0]
print len(safe_vals)
