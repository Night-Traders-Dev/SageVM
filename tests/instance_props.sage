class Box:
    proc init(self, val):
        self.value = val

var b = Box(100)
print b.value
b.value = 200
print b.value
b.other = "hello"
print b.other
