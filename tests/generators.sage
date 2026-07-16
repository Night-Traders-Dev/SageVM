# Test Generator semantics (OP_YIELD, OP_CREATE_GENERATOR, OP_GENERATOR_NEXT)
# NOTE: This test is expected to FAIL under the SVM interpreter due to a known gap:
# The SVM execution loop lacks standard native support for saving generator frame environments on OP_YIELD
# and resuming execution on OP_GENERATOR_NEXT.

proc simple_generator():
    print "Inside generator start"
    yield 10
    print "Inside generator middle"
    yield 20
    print "Inside generator end"

print "Creating generator..."
var gen = simple_generator()
print "Generator created."

print "Calling next(gen) 1:"
var val1 = next(gen)
print "Value 1:"
print val1

print "Calling next(gen) 2:"
var val2 = next(gen)
print "Value 2:"
print val2
