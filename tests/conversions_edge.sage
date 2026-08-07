# Test conversion builtins edge cases in SVM/SRVM.
# This covers int() and tonumber() conversions.
# Edge cases:
# - Conversions of nil or empty values
# - Conversions of boolean values
# - Conversions of invalid/whitespace strings
# - Conversions of scientific notation strings
#
# BUG/GAP: tonumber() with leading/trailing whitespaces (e.g. "  3.14  ")
# evaluates to nil instead of trimming and parsing the number.

print "--- int() edge cases ---"
print "int(nil): " + str(int(nil))
print "int(true): " + str(int(true))
print "int(false): " + str(int(false))
print "int('12.5'): " + str(int("12.5"))
print "int('invalid'): " + str(int("invalid"))
print "int(''): " + str(int(""))

print "--- tonumber() edge cases ---"
print "tonumber(''): " + str(tonumber(""))
print "tonumber(nil) == nil: " + str(tonumber(nil) == nil)
print "tonumber('  3.14  '): " + str(tonumber("  3.14  "))
print "tonumber('1e3'): " + str(tonumber("1e3"))
print "tonumber('invalid') == nil: " + str(tonumber("invalid") == nil)
