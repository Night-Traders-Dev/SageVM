# Test multi-level class inheritance, method overriding, and missing method calls.

class Base:
    proc greet(self):
        print "Base greeting"

    proc identify(self):
        print "I am Base"

class Child(Base):
    proc identify(self):
        print "I am Child"

class GrandChild(Child):
    proc extra(self):
        print "GrandChild extra"

print "--- Base class ---"
var b = Base()
b.greet()
b.identify()

print "--- Child class (inherited + overridden) ---"
var c = Child()
c.greet()
c.identify()

print "--- GrandChild class (multi-level inheritance) ---"
var g = GrandChild()
g.greet()
g.identify()
g.extra()
