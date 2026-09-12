# Test restricting definition of internal methods (__ prefix) in safe_mode

class MyClass:
    proc init(self):
        self.x = 1

    proc __secret_method(self):
        return 42

print "Internal method test complete"
