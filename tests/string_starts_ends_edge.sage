# Edge case tests for startswith and endswith string builtins
var s = "SageVM Compiler"

# Exact and standard matches
print startswith(s, "Sage")
print endswith(s, "Compiler")

# False matches
print startswith(s, "VM")
print endswith(s, "Sage")

# Empty prefix and suffix
print startswith(s, "")
print endswith(s, "")

# Target equals exact full string
print startswith(s, "SageVM Compiler")
print endswith(s, "SageVM Compiler")

# Prefix/suffix longer than target string
print startswith(s, "SageVM Compiler Suite")
print endswith(s, "The SageVM Compiler")

# Case sensitivity checks
print startswith(s, "sage")
print endswith(s, "compiler")

# Empty target string
print startswith("", "a")
print endswith("", "a")
print startswith("", "")
print endswith("", "")

# Nil argument handling
print startswith(nil, "Sage")
print endswith(s, nil)
print startswith(nil, nil)
