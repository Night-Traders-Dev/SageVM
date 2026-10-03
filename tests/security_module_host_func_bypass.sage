# Test that host native functions on module wrappers are restricted in safe mode when called as methods
import math
let m = {"__type__": "module", "f": math.sqrt}
print "Calling module host fn via method dispatch:"
m.f(16)
print "done"
