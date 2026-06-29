import math
try:
    math.sqrt = "hacked"
    if math.sqrt == "hacked":
        print "VULNERABLE: math.sqrt overwritten!"
    else:
        print "SUCCESS: math.sqrt protected (write failed silently)"
catch e:
    print "SUCCESS: math.sqrt protected (error caught)"
