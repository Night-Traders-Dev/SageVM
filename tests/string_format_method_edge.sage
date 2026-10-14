# Test chained string transformation methods and boundary cases

print "1. Chained string transformations:"
var s = "  Hello, SageVM World!  "
var clean_upper = upper(strip(s))
print clean_upper

var clean_replaced = replace(clean_upper, "WORLD", "UNIVERSE")
print clean_replaced

print "2. Split and Join chaining:"
var parts = split(clean_replaced, " ")
print parts
var rejoined = join(parts, "---")
print rejoined

print "3. Ord and Chr conversions:"
var char_a = chr(65)
print char_a
var code_a = ord("A")
print code_a
var code_first = ord("SageVM")
print code_first

print "4. Empty string boundary cases:"
print upper("")
print lower("")
print strip("")
print replace("", "a", "b")
print split("", ",")
print join([], ",")
