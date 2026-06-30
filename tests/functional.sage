proc add(a, b):
    return a + b

proc sub(a, b):
    return a - b

proc operate(f, x, y):
    return f(x, y)

print operate(add, 5, 3)
print operate(sub, 10, 4)

proc get_op(name):
    if name == "add":
        return add
    return sub

var op = get_op("add")
print op(10, 20)
