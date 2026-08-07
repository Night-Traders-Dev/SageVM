# Test bitwise shifts edge cases in SVM/SRVM.
# Standard left shift is handled via OP_SHIFT_LEFT, and right shift via OP_SHIFT_RIGHT.
# Edge cases:
# - Shifts with nil operand (coerced to 0 in VM)
# - Shifts with float values (coerced or truncated in VM)
# - Shifts with negative shift counts (uses host behavior)

print "--- Shifts with nil ---"
print nil << 2
print 10 << nil
print nil >> 2
print 10 >> nil

print "--- Shifts with float values ---"
print 10.5 << 1
print 10 << 1.5
print 10.5 >> 1
print 10 >> 1.5

print "--- Shifts with negative shift counts ---"
# Note: Negative shifts in Python/SageLang typically raise ValueError: negative shift count.
# Let's wrap in a try-catch block to handle host errors gracefully without crashing the VM.
try:
    print 10 << -1
catch e1:
    print "Error caught on negative shift left: " + str(e1)

try:
    print 10 >> -1
catch e2:
    print "Error caught on negative shift right: " + str(e2)
