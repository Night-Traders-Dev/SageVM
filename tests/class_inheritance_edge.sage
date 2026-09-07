# Test multi-level class inheritance, method overriding, and missing method calls (OP_CLASS, OP_METHOD, OP_INHERIT)

class GrandParent:
    proc init(self, name):
        self.name = name

    proc legacy(self):
        print "GrandParent legacy: " + self.name

    proc speak(self):
        print "GrandParent noise"

class Parent(GrandParent):
    proc speak(self):
        print "Parent voice: " + self.name

    proc parent_only(self):
        print "Parent exclusive method"

class Child(Parent):
    proc speak(self):
        print "Child shout: " + self.name

# Test multi-level instance creation
var p = Parent("Alex")
p.legacy()
p.speak()
p.parent_only()

var c = Child("Sam")
c.legacy()       # Inherited from GrandParent via Parent
c.parent_only()  # Inherited from Parent
c.speak()        # Overridden in Child

# Test calling non-existent method on instance
print "Calling missing method:"
var res = c.missing_method()
print "Missing method result: " + str(res)
