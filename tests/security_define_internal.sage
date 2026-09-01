# Test restricting definition of internal/reserved names (__ prefix) in safe_mode

var __secret_var = 42

print "Internal variable test complete"

class __SecretClass:
    proc init(self):
        self.x = 1

print "Internal class test complete"
