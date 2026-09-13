# Test multi-level class inheritance, method overriding, and missing method calls (OP_CLASS, OP_METHOD, OP_INHERIT)

class GrandParent:
    proc msg(self):
        return "GrandParent"

class Parent(GrandParent):
    proc parent_msg(self):
        return "Parent"

class Child(Parent):
    proc msg(self):
        return "Child"

var c = Child()
print "Child msg: " + c.msg()
print "Child parent_msg: " + c.parent_msg()

# Calling missing method
print "Missing method:"
c.unknown_method()
