# Test restricting definition of internal/reserved method names (__ prefix) in safe_mode

class UserClass:
    proc normal_method(self):
        return 1

    proc __internal_method(self):
        return 2

print "Internal method test complete"
