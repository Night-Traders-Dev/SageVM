# Test string searching, indexing, length, and substring method edge cases

print "--- String Length & Indexing ---"
var str1 = "SageVM"
print "len: " + str(len(str1))
print "char[0]: " + str1[0]
print "char[5]: " + str1[5]
print "char[10] == nil: " + str(str1[10] == nil)
print "char[-1]: " + str(str1[-1])

print "--- Contains Builtin ---"
print "contains Sage: " + str(contains(str1, "Sage"))
print "contains VM: " + str(contains(str1, "VM"))
print "contains xyz: " + str(contains(str1, "xyz"))
print "contains empty: " + str(contains(str1, ""))

print "--- StartsWith & EndsWith ---"
print "startswith Sage: " + str(startswith(str1, "Sage"))
print "startswith VM: " + str(startswith(str1, "VM"))
print "endswith VM: " + str(endswith(str1, "VM"))
print "endswith Sage: " + str(endswith(str1, "Sage"))

print "--- Replace Builtin ---"
var str2 = "banana"
print "replace a with o: " + replace(str2, "a", "o")
print "replace na with XX: " + replace(str2, "na", "XX")
print "replace empty: " + replace(str2, "", "-")

print "--- Strip, Upper, Lower ---"
var str3 = "  hello WORLD  "
print "strip: '" + strip(str3) + "'"
print "upper: " + upper(str3)
print "lower: " + lower(str3)

print "--- Substring Slicing ---"
print "slice 0..4: " + slice(str1, 0, 4)
print "slice 2..6: " + slice(str1, 2, 6)
