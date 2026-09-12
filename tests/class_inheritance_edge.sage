# Test multi-level class inheritance, method overriding, superclass method resolution, and edge access on missing properties/methods.

class Base:
    proc init(self, val):
        self.val = val

    proc get_val(self):
        return self.val

    proc describe(self):
        return "Base val: " + str(self.val)

class Child(Base):
    proc describe(self):
        return "Child val: " + str(self.val)

class GrandChild(Child):
    proc extra(self):
        return "GrandChild extra feature"

print "--- Multi-level Inheritance & Overriding ---"
var g = GrandChild(100)
print "g.get_val(): " + str(g.get_val())
print "g.describe(): " + g.describe()
print "g.extra(): " + g.extra()

print "--- Missing Property / Method Access ---"
var b = Base(42)
print "b.val: " + str(b.val)
print "b.missing_prop == nil: " + str(b.missing_prop == nil)
print "b.missing_method == nil: " + str(b.missing_method == nil)
