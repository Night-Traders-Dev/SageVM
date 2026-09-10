# Test that attempting to inherit from a protected host object (e.g. math) in safe mode is restricted.

class Child(math):
    proc init(self):
        return nil

print "Inheritance test finished"
