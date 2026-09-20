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

# inherited method resolution, and missing method calls on instances.

print "--- Multi-level class inheritance & overriding ---"
class Animal:
    proc init(self, name):
        self.name = name

    proc speak(self):
        print self.name + " makes a generic sound"

    proc category(self):
        print "Living Being"

class Dog(Animal):
    proc init(self, name, breed):
        Animal.init(self, name)
        self.breed = breed

    proc speak(self):
        print self.name + " (" + self.breed + ") barks"

class Puppy(Dog):
    proc yip(self):
        print self.name + " yips loudly!"

var a = Animal("Generic")
a.speak()
a.category()

var d = Dog("Buddy", "Golden")
d.speak()
d.category()

var p = Puppy("Max", "Beagle")
p.speak()
p.category()
p.yip()

print "--- Instance property access ---"
print "Puppy name: " + p.name
print "Puppy breed: " + p.breed


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


class BaseComponent:
    proc init(self, id):
        self.id = id

    proc describe(self):
        print "BaseComponent ID: " + str(self.id)

    proc base_only(self):
        print "Base only method executed for ID: " + str(self.id)

class UIElement(BaseComponent):
    proc init(self, id, visible):
        self.id = id
        self.visible = visible

    proc describe(self):
        print "UIElement ID: " + str(self.id) + ", visible: " + str(self.visible)

class Button(UIElement):
    proc init(self, id, visible, label):
        self.id = id
        self.visible = visible
        self.label = label

    proc describe(self):
        print "Button ID: " + str(self.id) + " ['" + str(self.label) + "'], visible: " + str(self.visible)

    proc click(self):
        print "Button " + str(self.label) + " clicked!"

print "--- Multi-level Inheritance & Overriding ---"
var b = Button(101, true, "Submit")
b.describe()
b.click()

print "--- Grandparent Method Inheritance ---"
b.base_only()

print "--- Parent Class Instance ---"
var elem = UIElement(202, false)
elem.describe()
elem.base_only()

print "--- Non-existent Property Edge Case ---"
print "elem.non_existent == nil: " + str(elem.non_existent == nil)
