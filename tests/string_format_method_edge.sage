print "--- Chained String Transformations ---"
var raw = "  \t Hello SageVM World \n "
var cleaned = strip(raw)
print cleaned
var upper_str = upper(cleaned)
print upper_str
var lower_str = lower(upper_str)
print lower_str
var replaced = replace(upper_str, "WORLD", "ENGINE")
print replaced

print "--- Character Code Conversions ---"
print ord("A")
print chr(65)
print chr(ord("Z"))
print ord(chr(97))

print "--- Empty String & Collection Boundaries ---"
var empty_split = split("", ",")
print len(empty_split)

var empty_join = join([], "-")
print len(empty_join)

var empty_rep = replace("sage", "", "X")
print empty_rep
