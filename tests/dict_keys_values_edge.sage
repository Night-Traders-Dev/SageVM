let empty_d = {}
print "Empty keys len:"
print len(dict_keys(empty_d))
print "Empty values len:"
print len(dict_values(empty_d))

print "Nil keys len:"
print len(dict_keys(nil))
print "Nil values len:"
print len(dict_values(nil))

print "Has on empty:"
print dict_has(empty_d, "a")
print "Has on nil:"
print dict_has(nil, "a")

let d = {"x": 10, "y": 20}
print "Has x:"
print dict_has(d, "x")
print "Keys len:"
print len(dict_keys(d))
print "Values len:"
print len(dict_values(d))
