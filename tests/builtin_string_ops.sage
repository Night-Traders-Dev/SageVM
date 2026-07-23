# Test string builtin operations
let s = "Hello World"
print startswith(s, "Hello")
print endswith(s, "World")
print contains(s, "lo Wo")
print upper("hello")
print lower("HELLO")
print strip("  hello  ")
print replace("hello world", "world", "sage")
print join(["a", "b", "c"], "-")
