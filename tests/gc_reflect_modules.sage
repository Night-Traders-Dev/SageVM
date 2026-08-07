# Test GC and Reflection module and builtin features.
# CONFORMANCE BUG/GAP: In SVM, 'gc' and 'reflect' are populated as pre-defined global dictionaries in setup_builtins().
# However, if a guest script explicitly calls `import gc` or `import reflect`, the compiler generates an OP_IMPORT
# which results in the VM pushing an empty dummy module dictionary {"__type__": "module", "__name__": "gc"/"reflect"}
# and assigning it to the global variable, completely destroying the pre-existing pre-populated dictionaries.

print "1. Testing predefined global gc dictionary..."
print "Predefined gc is dict: " + str(type(gc) == "dict")
print "Predefined gc.collect exists: " + str(gc.collect != nil)
print "Predefined gc.stats exists: " + str(gc.stats != nil)

print "2. Testing predefined global reflect dictionary..."
print "Predefined reflect is dict: " + str(type(reflect) == "dict")
print "Predefined reflect.get_class exists: " + str(reflect.get_class != nil)

# Now show the shadowing/erasing behavior on explicit import (bug/gap)
import gc
import reflect

print "3. Testing gc after explicit import..."
print "Imported gc is dict: " + str(type(gc) == "dict")
# These will now evaluate to false because OP_IMPORT overwrote them with an empty module dict!
print "Imported gc.collect exists: " + str(gc.collect != nil)
print "Imported gc.stats exists: " + str(gc.stats != nil)

print "4. Testing reflect after explicit import..."
print "Imported reflect is dict: " + str(type(reflect) == "dict")
print "Imported reflect.get_class exists: " + str(reflect.get_class != nil)
