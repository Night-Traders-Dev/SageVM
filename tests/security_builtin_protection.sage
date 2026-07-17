# Test Builtin Protection & Mutation protection under safe mode
# Specifically, we verify that mutation of __builtin__-tagged structures or core globals
# raises an error or is blocked under safe mode (isolated environment).

# Attempt to access sensitive properties in dictionary/host structures
var test_dict = {"__builtin__": true, "value": 42}
print "Dictionary created with __builtin__ property."

# This is a test of safe mutation blocking of __builtin__ tagged objects
try:
    test_dict.value = 100
    print "Mutation allowed: " + str(test_dict.value)
catch e:
    print "Caught exception during mutation"

# Attempt to mutate a standard dictionary under the same rules
var normal_dict = {"value": 42}
normal_dict.value = 100
print "Normal mutation: " + str(normal_dict.value)
