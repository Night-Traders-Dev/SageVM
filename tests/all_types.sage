print "1: " + type(1)
print "3.14: " + type(3.14)
print "nil: " + type(nil)
print "true: " + type(true)
print "string: " + type("hello")
print "array: " + type([1, 2])
print "dict: " + type({"a": 1})

# BUG: The SVM backend currently returns "dict" for modules, functions, classes, and instances
# because they are implemented as dictionaries with a __type__ tag, and the host type()
# builtin is not yet aware of this guest-side abstraction.
import math
print "module: " + type(math)

proc f():
    pass
print "function: " + type(f)

class C:
    proc init(self):
        pass
print "class: " + type(C)
print "instance: " + type(C())
