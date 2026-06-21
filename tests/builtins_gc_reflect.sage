# Test GC built-ins
print "GC Stats:"
var stats = gc_stats()
if type(stats["num_objects"]) == "number":
    print "num_objects is a number"
else:
    print "num_objects is " + type(stats["num_objects"])

print gc_collect()
print gc_enable()
print gc_disable()

# Test Reflection built-ins
print "Reflection:"
var methods = reflect_get_methods(1)
print len(methods)
print reflect_get_class(1)
