import math

# Security Test: Verify contains does not leak protected object metadata or internal keys in safe mode
print contains("hello world", "world")
print contains("hello world", "__host_mod__")
print contains(math, "pi")
print contains(math, "__host_mod__")

let d = {"a": 1, "__secret": 2}
print contains(d, "__secret")
