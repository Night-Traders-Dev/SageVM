var d = {"__builtin__": "test"}
print "Attempting to modify dict with __builtin__ key in safe mode..."

# Test index assignment
d["attack"] = "success"
if d["attack"] == "success":
    print "RESULT: FAIL - Modification allowed"
else:
    print "RESULT: PASS - Modification restricted"

# Test property assignment
try:
    d.attack2 = "success"
catch e:
    pass
end

if d.attack2 == "success":
    print "RESULT: FAIL - Property modification allowed"
else:
    print "RESULT: PASS - Property modification restricted"
