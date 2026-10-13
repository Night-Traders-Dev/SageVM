# Test chained string builtins, ASCII conversions, character shifts, and empty string edge cases

print "--- Chained strip and case conversion ---"
var raw_str = "  Hello SageVM World!  "
var clean_upper = upper(strip(raw_str))
print "clean_upper: '" + clean_upper + "'"

var clean_lower = lower(replace(raw_str, "World", "Community"))
print "clean_lower: '" + clean_lower + "'"

print "--- Split and re-join with new delimiter ---"
var csv_line = "apple,banana,cherry"
var fruits = split(csv_line, ",")
print "fruits count: " + str(len(fruits))
var joined_str = join(fruits, " | ")
print "joined_str: " + joined_str

print "--- ASCII char manipulation loop ---"
var msg = "ABC"
var shifted = ""
for i in range(len(msg)):
    var code = ord(msg[i])
    var next_char = chr(code + 1)
    shifted = shifted + next_char
print "shifted 'ABC' + 1: " + shifted

print "--- Empty string boundary cases ---"
print "upper(''): '" + upper("") + "'"
print "lower(''): '" + lower("") + "'"
print "strip(''): '" + strip("") + "'"
var empty_join = join([], ",")
print "join([], ','): '" + empty_join + "'"
