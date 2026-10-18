print "--- Chained String Operations ---"
var raw = "   hello_world_sagevm   "
var cleaned = strip(raw)
print cleaned

var upper_c = upper(cleaned)
print upper_c

var formatted = replace(upper_c, "_", " ")
print formatted

print "--- Split and Join Operations ---"
var parts = split(formatted, " ")
print parts
print len(parts)

var rejoined = join(parts, " - ")
print rejoined

var lowered = lower(rejoined)
print lowered

print "--- Character Conversions ---"
var char_a = chr(65)
print char_a
print ord(char_a)

var char_z = chr(122)
print char_z
print ord(char_z)

print "--- Empty String Boundary Cases ---"
var empty_str = ""
print strip(empty_str)
print upper(empty_str)
print lower(empty_str)
print replace(empty_str, "a", "b")
print split(empty_str, ",")
print join([], "x")
