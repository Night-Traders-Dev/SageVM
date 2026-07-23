# Test split and join
let parts = split("hello world sage", " ")
print len(parts)
print parts[0]
print parts[1]
print parts[2]
let joined = join(parts, ",")
print joined
