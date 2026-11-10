print "--- Chained String Transformation Builtins ---"
var raw = "  Hello, SageVM World!  "
var cleaned = lower(strip(raw))
print cleaned

print "--- Replace + Split + Join Pipeline ---"
var sentence = "apple,banana,cherry"
var relabeled = replace(sentence, "banana", "orange")
var parts = split(relabeled, ",")
print parts
var joined = join(parts, " | ")
print joined

print "--- Character Code Conversions ---"
var first_char = parts[0][0]
var code = ord(first_char)
print code
print chr(code)

print "--- Empty String Boundary Pipeline ---"
var empty_str = ""
print upper(empty_str)
print strip(empty_str)
print split(empty_str, ",")
