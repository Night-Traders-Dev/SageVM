# Test split and join edge cases
print "Split empty string:"
var sp1 = split("", ",")
print len(sp1)

print "Split string separator not found:"
var sp2 = split("hello world", ",")
print len(sp2)
print sp2[0]

print "Split nil input:"
print split(nil, ",")

print "Join empty array:"
print join([], "-")

print "Join nil input:"
print join(nil, "-")
