import math
let h = math.__host_mod__
if h == nil:
    print "SUCCESS: internal leak prevented"
else:
    print "VULNERABLE: internal leak"
