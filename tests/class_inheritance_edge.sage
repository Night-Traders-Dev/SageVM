# Test multi-level class inheritance (OP_CLASS, OP_METHOD, OP_INHERIT), method overriding,
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
