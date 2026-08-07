# Test thread module bridging behavior in SVM backend.
# CONFORMANCE BUG/GAP: Predefined global 'thread' dictionary is registered as
# {"__host_mod__": host_thread} during setup_builtins(), which does not define a 'mutex' attribute inside the VM's dict.
# Thus, trying to call `thread.mutex()` without explicit `import thread` fails with a method-not-found error.
# After calling `import thread`, the VM maps "mutex" to "__builtin_thread_mutex", which runs and returns nil.

print "1. Accessing thread without explicit import..."
print "Thread global dict is dict: " + str(type(thread) == "dict")
print "Thread mutex: " + str(thread.mutex) # Method mutex not found -> nil

# Now we call import thread to correctly map the mutex builtin
import thread

print "2. Accessing thread with explicit import..."
print "Imported thread is dict: " + str(type(thread) == "dict")
print "Imported thread mutex is function-like: " + str(thread.mutex != nil)
var m = thread.mutex()
print "Result of thread.mutex(): " + str(m)
