import math

# Security Test: Verify dict_values filters nil and host native functions under safe mode
let vals = dict_values(math)
# math in safe_mode has pi, e, printm.
# abs, sqrt, sin, cos evaluate to nil in safe_mode and are filtered out by dict_values.
print len(vals)

let d = {"visible": 10, "__internal": 20}
let safe_keys = dict_keys(d)
let safe_vals = dict_values(d)
print safe_keys[0]
print safe_vals[0]
print len(safe_vals)
