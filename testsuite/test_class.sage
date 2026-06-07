# test_class.sage
# Minimal class definition and instantiation test for Phase 2 bytecode diagnosis.
# Expected output:
#   Point created
#   x=3 y=4
#   distance=5.0

class Point:
    proc init(self, x, y):
        self.x = x
        self.y = y

    proc describe(self):
        print("x=" + str(self.x) + " y=" + str(self.y))

    proc distance(self):
        return (self.x * self.x + self.y * self.y) ^ 0.5

var p = Point(3, 4)
print("Point created")
p.describe()
print("distance=" + str(p.distance()))
