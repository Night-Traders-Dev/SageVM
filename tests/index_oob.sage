var a = [10, 20]
print "Array[0]: " + str(a[0])
print "Array[5]: " + str(a[5])
print "Array[-1]: " + str(a[-1])

var d = {"x": 100}
print "Dict['x']: " + str(d["x"])
print "Dict['y']: " + str(d["y"])

# Test indexing nil
var n = nil
try:
    print n[0]
catch e:
    print "Caught error indexing nil: " + str(e)
