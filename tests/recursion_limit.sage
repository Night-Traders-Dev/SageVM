proc f(n):
    if n == 1023:
        print "Reached limit"
    f(n + 1)

f(1)
