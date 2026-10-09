# Test string escape sequences, multi-line string handling, and string builtins

print "--- String Escape Sequences ---"
var newline = "Hello\nWorld"
print newline

var tabbed = "Col1\tCol2\tCol3"
print tabbed

var quote_slash = "Quote: \"Slash: \\"
print quote_slash

print "--- String Length and Indexing with Escapes ---"
print "len(newline): " + str(len(newline))
print "newline[5] == \\n: " + str(newline[5] == "\n")
print "ord(\\n): " + str(ord("\n"))
print "ord(\\t): " + str(ord("\t"))
print "chr(10) == \\n: " + str(chr(10) == "\n")

print "--- String Split with Newline / Tab ---"
var lines = split(newline, "\n")
print "lines count: " + str(len(lines))
print "line 0: " + lines[0]
print "line 1: " + lines[1]

var joined = join(lines, " -> ")
print "joined: " + joined

print "--- Strip Whitespace and Newlines ---"
var raw = "  \t\n  padded string  \n\t  "
var cleaned = strip(raw)
print "cleaned: [" + cleaned + "]"
