print "--- range single-arg and edge cases ---"
print range(0)
print range(5)
print range(-3)
print range(nil)
print range("invalid")

print "--- clock builtin sanity check ---"
let t1 = clock()
print type(t1)
print t1 >= 0
