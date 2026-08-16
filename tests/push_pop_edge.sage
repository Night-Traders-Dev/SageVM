let arr = []
print "Initial len:"
print len(arr)

print "Pop empty array:"
let p1 = pop(arr)
print p1
print "Len after pop empty:"
print len(arr)

push(arr, "first")
push(arr, "second")
push(arr, "third")
print "Len after 3 pushes:"
print len(arr)

print "Pop 1:"
print pop(arr)
print "Pop 2:"
print pop(arr)
print "Len remaining:"
print len(arr)

print "Push nil:"
push(arr, nil)
print "Len after push nil:"
print len(arr)
print "Pop nil:"
print pop(arr)
