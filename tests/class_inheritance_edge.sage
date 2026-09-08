# Test multi-level class inheritance, method overriding, and missing method dispatch (OP_CLASS, OP_METHOD, OP_INHERIT)

print "--- Multi-level Inheritance & Method Overriding ---"
class Base:
    proc greet(self):
        print "Hello from Base"

class Middle(Base):
    proc identify(self):
        print "Middle class"

class Sub(Middle):
    proc greet(self):
        print "Overridden in Sub"

var s = Sub()
s.greet()
s.identify()

print "--- Missing Method Call ---"
s.non_existent_method()
