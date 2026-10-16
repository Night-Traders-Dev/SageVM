import math

# Security Test: Verify contains does not probe protected objects/modules or internal keys in safe mode
let s = "hello world __secret"

print contains(s, "world")
print contains(s, "__secret")
print contains(math, "abs")
print contains(math, "__host_mod__")
