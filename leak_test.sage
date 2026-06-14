proc test():
    try:
        return 1
    catch e:
        print "caught in test"

test()
raise "error"
