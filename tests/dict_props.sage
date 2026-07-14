var d = {"a": 1, "b": 2}
print d.a
print d.b
d.c = 3
print d.c
print d.a + d.b + d.c

# Test on nested dict
var nested = {"inner": {"x": 10}}
print nested.inner.x
nested.inner.y = 20
print nested.inner.y
