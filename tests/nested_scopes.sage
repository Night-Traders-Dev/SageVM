let x = "global"

proc outer():
    let x = "outer"

    proc inner():
        # SGVM currently doesn't support closures (lexical capture),
        # but it supports dynamic lookup in the scope stack.
        # This test verifies how shadowing works in nested contexts.
        print x

    inner()
    print x

outer()
print x
