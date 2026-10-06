# Test split() and join() builtins with multi-char delimiters, non-string arrays, empty delimiters, and boundary conditions.

print "--- Multi-character delimiter split ---"
var s1 = "alpha::beta::gamma"
var parts1 = split(s1, "::")
print "Len: " + str(len(parts1))
print parts1[0]
print parts1[1]
print parts1[2]

print "--- Empty string delimiter split ---"
var s2 = "abc"
var parts2 = split(s2, "")
print "Len empty sep: " + str(len(parts2))

print "--- Join array with mixed types ---"
var arr_mixed = ["item", 42, true, nil, "end"]
var j1 = join(arr_mixed, "-")
print "Joined mixed: " + str(j1)

print "--- Join empty array ---"
var j2 = join([], ",")
print "Joined empty: '" + str(j2) + "'"

print "--- Join single element array ---"
var j3 = join(["solo"], "--")
print "Joined single: " + str(j3)

print "--- Join with empty delimiter ---"
var j4 = join(["x", "y", "z"], "")
print "Joined empty sep: " + str(j4)

print "--- Nil parameters ---"
print "split(nil, ','): " + str(split(nil, ","))
print "join(nil, '-'): " + str(join(nil, "-"))
