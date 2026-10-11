# Test string escape sequences, multi-line string length/indexing, ord/chr conversions,
# split/join on newline delimiters, and strip whitespace/newline trimming.

print "--- Escape Sequences & Multi-line ---"
let s = "hello\nworld\ttab\\slash"
print len(s)
print ord(s[5])

print "--- Split and Join on Newline ---"
let lines = split("line1\nline2\nline3", "\n")
print len(lines)
print lines[0]
print lines[1]
print lines[2]
print join(lines, "---")

print "--- Strip Whitespace and Newlines ---"
print strip("\n\t hello world  \r\n")
