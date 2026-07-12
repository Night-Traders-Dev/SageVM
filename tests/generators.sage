# Test generators (OP_YIELD, OP_CREATE_GENERATOR, OP_GENERATOR_NEXT)
# BUG: The SageLang compiler (--emit-vm) currently fails to emit bytecode
# for 'yield' statements, and the SVM interpreter lacks support.

proc count(n):
    var i = 0
    while i < n:
        yield i
        i = i + 1
    return nil

# This will likely fail with "AST fallback" or runtime error
for x in count(3):
    print x
