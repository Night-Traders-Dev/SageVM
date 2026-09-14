# Test restricting class inheritance from protected host objects in safe_mode

import math

class BadClass(math):
    proc init(self):
        nil

print "Security test complete"
