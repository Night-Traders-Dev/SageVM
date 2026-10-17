print "=== String Indexing & Length ==="
var text = "SageVM"
print len(text)
print text[0]
print text[3]
print text[5]
print text[6]
print text[-1]

print "=== String Search Functions ==="
print contains(text, "geV")
print contains(text, "xyz")
print contains("", "a")
print startswith(text, "Sage")
print startswith(text, "VM")
print endswith(text, "VM")
print endswith(text, "Sage")

print "=== String Transformation Builtins ==="
print upper(text)
print lower(text)
print strip("   hello world   ")
print replace(text, "VM", "Lang")
print slice(text, 0, 4)

print "=== Boundary & Nil Cases ==="
print len("")
print text[100]
print contains(text, "")
print startswith(text, "")
print endswith(text, "")
