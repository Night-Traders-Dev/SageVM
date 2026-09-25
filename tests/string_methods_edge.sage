# Test string manipulation builtins with edge and boundary conditions

# 1. replace
print "--- replace ---"
print replace("hello world", "world", "sage")
print replace("aaaaa", "a", "b")
print replace("abc", "d", "x")
print replace("", "a", "b")
print replace("hello", "", "X")

# 2. strip
print "--- strip ---"
print strip("  hello world  ")
print strip("\t\n  sagevm  \r\n")
print strip("no_spaces")
print strip("")

# 3. upper and lower
print "--- upper/lower ---"
print upper("sagevm 1.2.1!")
print lower("SAGEVM 1.2.1!")
print upper("")
print lower("")

# 4. startswith and endswith
print "--- startswith/endswith ---"
print startswith("sagevm", "sage")
print startswith("sagevm", "vm")
print startswith("sagevm", "")
print endswith("sagevm", "vm")
print endswith("sagevm", "sage")
print endswith("sagevm", "")

# 5. split and join
print "--- split/join ---"
var parts = split("one,two,three", ",")
print parts
print join(parts, " - ")
print split("hello", "")
print join([], ",")

# 6. slice on strings
print "--- slice ---"
print slice("sagevm", 0, 4)
print slice("sagevm", 2, 10)
print slice("sagevm", 10, 20)
print slice("", 0, 5)
