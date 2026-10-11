# Test early function returns (OP_RETURN) from deep nested block scopes, loops, and try-catch blocks.

proc test_nested_return(mode):
    if mode > 0:
        var i = 0
        while i < 10:
            i = i + 1
            if i == 5:
                try:
                    if mode == 1:
                        return "return_from_try"
                    raise "err"
                catch err:
                    return "return_from_catch: " + str(err)
    return "default_return"

print test_nested_return(1)
print test_nested_return(2)
print test_nested_return(0)
