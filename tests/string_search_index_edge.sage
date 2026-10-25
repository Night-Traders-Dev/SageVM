print "--- String Indexing and Length ---"
var s = "SageVM 2026"
print len(s)
print s[0]
print s[6]
print s[10]
print s[11]

print "--- String Contains & Searches ---"
print contains(s, "VM")
print contains(s, "xyz")
print startswith(s, "Sage")
print startswith(s, "VM")
print endswith(s, "2026")
print endswith(s, "Sage")

print "--- String Slicing and Transformation ---"
print slice(s, 0, 6)
print slice(s, 7, 11)
print upper("sagevm")
print lower("SAGEVM")
print strip("   sagevm   ")
print replace("a-b-c", "-", ":")

print "--- Ord and Chr conversions ---"
print ord("A")
print ord("z")
print chr(65)
print chr(122)