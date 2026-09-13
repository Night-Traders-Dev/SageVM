# Test restricting definition of internal methods (__ prefix) in safe_mode

class NormalClass:
    proc __internal_method(self):
        return 42

print "Internal method test complete"
