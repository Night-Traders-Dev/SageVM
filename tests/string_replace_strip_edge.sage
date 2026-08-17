print "Replace non-existent:"
print replace("hello", "xyz", "abc")

print "Replace empty target:"
print replace("hello", "", "-")

print "Replace multiple:"
print replace("a-b-a-b", "a", "x")

print "Strip no spaces:"
print strip("hello")

print "Strip all spaces:"
print strip("   ")

print "Strip mixed spaces:"
print strip("  \t hello world \t  ")

print "Upper/Lower empty:"
print upper("")
print lower("")
