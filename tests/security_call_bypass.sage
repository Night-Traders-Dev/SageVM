import math
let h = math.__host_mod__()
if h != nil:
    print "VULNERABLE: leaked host mod"
else:
    print "SAFE"
