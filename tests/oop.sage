# Test OOP features (OP_CLASS, OP_METHOD, OP_INHERIT)
# NOTE: This test is expected to FAIL due to an opcode collision at index 59.
# The host compiler emits OP_GET_LOCAL (59 in authoritative bytecode.h) which
# the VM incorrectly interprets as OP_GPU_POLL_EVENTS (59 in SVM mapping).
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
