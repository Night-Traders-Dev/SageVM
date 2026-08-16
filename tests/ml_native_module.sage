# Test ml_native module bridging
import ml_native

print "ml_native type:"
print type(ml_native)

print "dict_has ml_native __host_mod__:"
print dict_has(ml_native, "__host_mod__")
