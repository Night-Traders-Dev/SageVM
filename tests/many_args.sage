proc sum8(a, b, c, d, e, f, g, h):
    return a + b + c + d + e + f + g + h

print "Sum 1..8:"
print sum8(1, 2, 3, 4, 5, 6, 7, 8)

proc recurse_many(n, a, b, c):
    if n == 0:
        return a
    return recurse_many(n - 1, a + 1, b, c)

print "Recurse many (depth 5):"
print recurse_many(5, 10, 20, 30)
