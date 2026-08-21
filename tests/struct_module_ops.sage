import struct

print "Testing struct module edge cases..."
print "Struct def valid: " + str(struct.def("i") != nil)
print "Struct def invalid: " + str(struct.def("invalid_fmt"))
print "Struct def nil: " + str(struct.def(nil))

var s_def = struct.def("ii")
if s_def != nil:
    print "Struct def created"
    var inst = struct.new(s_def)
    print "Struct inst created: " + str(inst != nil)
    print "Struct size: " + str(struct.size(s_def))
    print "Struct set valid: " + str(struct.set(inst, 0, "i", 42))
    print "Struct get valid: " + str(struct.get(inst, 0, "i"))
    print "Struct set nil field: " + str(struct.set(inst, nil, "i", 42))
    print "Struct get nil field: " + str(struct.get(inst, nil, "i"))
else:
    # Documented host bridge behavior: struct.def returning nil under standalone interpreter environment
    print "Struct def failed (host bridge behavior)"
    print "Struct new nil: " + str(struct.new(nil))
    print "Struct size nil: " + str(struct.size(nil))
    print "Struct get nil: " + str(struct.get(nil, 0, "i"))
    print "Struct set nil: " + str(struct.set(nil, 0, "i", 42))
