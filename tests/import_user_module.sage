# Test OP_IMPORT for non-native modules
# Currently the SVM returns a dummy dictionary for modules it can't find or hasn't implemented dynamic loading for yet.

import my_custom_module
print type(my_custom_module)
print my_custom_module.__type__
print my_custom_module.__name__

# Importing a native module that is bridged
import math
print type(math)
print math.pi
