# Test chained string transformation builtins (upper, lower, strip, replace,
# split, join), character code conversions (ord, chr), and empty string boundary cases.

print "--- String Transformation Builtins & Chaining ---"
var raw = "  Hello, SageVM World!  "
var trimmed = strip(raw)
print trimmed

var upper_str = upper(trimmed)
print upper_str

var lower_str = lower(upper_str)
print lower_str

var replaced = replace(lower_str, "world", "universe")
print replaced

print "--- Split and Join Operations ---"
var parts = split(replaced, " ")
print len(parts)
print parts[0]
print parts[1]
print parts[2]

var rejoined = join(parts, "---")
print rejoined

print "--- Character Ord/Chr Conversions ---"
var c = "A"
var code = ord(c)
print code
print chr(code)
print chr(code + 32)

print "--- Empty String Boundaries ---"
print strip("")
print upper("")
print lower("")
print len(split("", ","))
print join([], ":")
