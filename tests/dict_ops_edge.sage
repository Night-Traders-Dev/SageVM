# Test dictionary operations, indexing, and property access edge cases

print "--- Property Access on Dicts vs Missing Keys ---"
var d = {}
d.name = "SageVM"
print "d.name: " + str(d.name)
print "d.missing == nil: " + str(d.missing == nil)
print "d['absent'] == nil: " + str(d["absent"] == nil)

print "--- String Key Indexing and Property Equivalency ---"
d["version"] = "1.2"
print "d.version: " + str(d.version)
print "d['version']: " + str(d["version"])

print "--- Nested Dictionary Property & Indexing ---"
var nested = {"outer": {"inner": 42}}
print "nested.outer.inner: " + str(nested.outer.inner)
print "nested['outer']['inner']: " + str(nested["outer"]["inner"])

print "--- Reassigning Nested Dictionary Values ---"
nested.outer.inner = 100
print "reassigned inner: " + str(nested.outer.inner)
