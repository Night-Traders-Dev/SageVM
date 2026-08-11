# Test string concatenation edge cases in SVM/SRVM.
# Standard string concatenation is handled via OP_ADD.
# Edge cases:
# - Concatenation with nil (converts to empty string in SVM backend)
# - Concatenation with array or dictionary (uses host string representation)
# - Concatenation with empty strings

print "--- Concat with nil ---"
print "prefix_" + nil
print nil + "_suffix"

print "--- Concat with collections ---"
# Arrays and dicts are converted using str() representation on host/guest
print "array: " + [1, 2, 3]
print {"key": "value"} + " is a dict"

print "--- Concat with empty strings ---"
print "" + "hello"
print "world" + ""
