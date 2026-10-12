# Test string escape sequences in SVM bytecode
print "--- Escape Sequences ---"
let s1 = "hello\nworld"
print s1
print "len s1: " + str(len(s1))

let s2 = "a\tb\tc"
print s2

let s3 = "line1\rline2"
print len(s3)

let s4 = "path\\to\\file"
print s4

let s5 = "say \"hello\""
print s5

print "--- String Functions with Escapes ---"
let parts = split(s1, "\n")
print "split len: " + str(len(parts))
print "part 0: " + str(parts[0])
print "part 1: " + str(parts[1])

let joined = join(parts, " -- ")
print "joined: " + str(joined)

let str_strip = strip("  \n\t hello \t\n  ")
print "stripped: " + str(str_strip)

print "ord newline: " + str(ord("\n"))
print "ord tab: " + str(ord("\t"))
print "chr 10 == newline: " + str(chr(10) == "\n")
