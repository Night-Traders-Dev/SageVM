# Test OOP features (OP_CLASS, OP_METHOD, OP_INHERIT)
class Animal:
    proc init(self, name):
        self.name = name

    proc speak(self):
        print self.name + " makes a sound"

class Dog(Animal):
    proc speak(self):
        print self.name + " barks"

var a = Animal("Generic")
a.speak()

var d = Dog("Buddy")
d.speak()
