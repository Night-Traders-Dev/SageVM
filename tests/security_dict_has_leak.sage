import math

# Security Test: Verify dict_has does not probe protected objects/modules in safe mode
print dict_has(math, "pi")
print dict_has(math, "abs")
print dict_has(math, "__host_mod__")

let d = {"a": 1, "__secret": 2}
print dict_has(d, "a")
print dict_has(d, "__secret")
