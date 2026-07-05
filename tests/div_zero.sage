# Test division and modulo by zero
# In SGVM, these should return nil rather than crashing the host.

print "10 / 0:"
print 10 / 0

print "10 % 0:"
print 10 % 0

print "1.0 / 0.0:"
print 1.0 / 0.0
