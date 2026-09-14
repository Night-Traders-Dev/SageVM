# Test multi-level class inheritance (OP_CLASS, OP_METHOD, OP_INHERIT), method overriding, and inherited method resolution.

class Base:
    proc init(self, val):
        self.val = val

    proc get_val(self):
        return self.val

    proc identify(self):
        return "Base"

class Child(Base):
    proc get_val(self):
        return self.val * 2

    proc identify(self):
        return "Child"

class Grandchild(Child):
    proc extra(self):
        return "extra_" + str(self.val)

print "--- Base class instance ---"
var b = Base(10)
print "Base val: " + str(b.get_val())
print "Base id: " + b.identify()

print "--- Child class instance (overrides & inherited init) ---"
var c = Child(15)
print "Child val: " + str(c.get_val())
print "Child id: " + c.identify()

print "--- Grandchild instance (multi-level inheritance) ---"
var g = Grandchild(20)
print "Grandchild val: " + str(g.get_val())
print "Grandchild id: " + g.identify()
print "Grandchild extra: " + g.extra()
