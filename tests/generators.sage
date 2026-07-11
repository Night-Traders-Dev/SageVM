proc count(n):
    var i = 0
    while i < n:
        yield i
        i = i + 1

var c = count(3)
print c.next()
print c.next()
print c.next()
