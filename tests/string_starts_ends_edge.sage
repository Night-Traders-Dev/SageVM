# String startswith and endswith edge cases
print startswith("hello world", "hello")
print startswith("hello world", "world")
print startswith("hello world", "")
print startswith("hello world", "hello world")
print startswith("hi", "hello world")

print endswith("hello world", "world")
print endswith("hello world", "hello")
print endswith("hello world", "")
print endswith("hello world", "hello world")
print endswith("hi", "hello world")

print startswith("Hello", "hello")
print endswith("Hello", "HELLO")

print startswith(nil, "a")
print endswith("hello", nil)
