# Test reflect_get_methods and reflect_get_class edge cases
print "Testing reflect builtins..."

# Class and instance reflection
class Animal:
    proc speak():
        print "generic sound"

let cat = Animal()

let cat_methods = reflect_get_methods(cat)
print "cat methods type: " + type(cat_methods)

let cat_cls = reflect_get_class(cat)
print "cat class type: " + type(cat_cls)

# Reflection on primitive types
print "int methods: " + str(reflect_get_methods(42))
print "int class: " + str(reflect_get_class(42))

print "string methods: " + str(reflect_get_methods("hello"))
print "string class: " + str(reflect_get_class("hello"))

print "nil methods: " + str(reflect_get_methods(nil))
print "nil class: " + str(reflect_get_class(nil))

print "array methods: " + str(reflect_get_methods([1, 2]))
print "dict methods: " + str(reflect_get_methods({"a": 1}))
