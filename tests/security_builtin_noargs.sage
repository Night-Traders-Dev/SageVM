let f_str = "__builtin_str"
let f_type = "__builtin_type"
let f_upper = "__builtin_upper"
let f_lower = "__builtin_lower"
let f_strip = "__builtin_strip"
let f_join = "__builtin_join"
let f_split = "__builtin_split"
let f_replace = "__builtin_replace"
let f_startswith = "__builtin_startswith"
let f_slice = "__builtin_slice"
let f_reflect = "__builtin_reflect_get_methods"

print "str: " + str(f_str())
print "type: " + str(f_type())
print "upper: " + str(f_upper())
print "lower: " + str(f_lower())
print "strip: " + str(f_strip())
print "join: " + str(f_join())
print "split len: " + str(len(f_split()))
print "replace: " + str(f_replace())
print "startswith: " + str(f_startswith())
print "slice: " + str(f_slice())
print "reflect len: " + str(len(f_reflect()))
