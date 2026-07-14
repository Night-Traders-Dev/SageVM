import non_existent_module

print "Module type: " + type(non_existent_module)
print "Module name: " + non_existent_module.__name__

# Accessing attribute of dummy module
print "Module attribute: " + str(non_existent_module.some_attr)
