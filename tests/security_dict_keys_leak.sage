import math

# Security Test: Verify dict_keys and dict_values do not leak protected object metadata in safe mode
print dict_keys(math)
print dict_values(math)

let d = {"a": 1, "__secret": 2}
print dict_keys(d)
print dict_values(d)
