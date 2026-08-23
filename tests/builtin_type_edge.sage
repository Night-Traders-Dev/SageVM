# Type builtin function coverage across types and edge cases
print type(123)
print type(3.14)
print type("hello")
print type(true)
print type(false)
print type(nil)
print type([1, 2, 3])
print type({"a": 1})
print type((1, 2))

proc sample_func():
    return 1

print type(sample_func)

var m = math
print type(m)
