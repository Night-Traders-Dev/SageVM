# Nested dictionary mutation and property access edge cases

print "--- Nested Dictionary Creation & Index Mutation ---"
var d = {"user": {"profile": {"name": "Alice", "role": "admin"}}}
print d["user"]["profile"]["name"]

d["user"]["profile"]["role"] = "superadmin"
print d["user"]["profile"]["role"]

d["user"]["profile"]["active"] = true
print d["user"]["profile"]["active"]

print "--- Dictionary Property Access vs Indexing ---"
var config = {"settings": {"theme": "dark"}}
print config.settings.theme

config.settings.theme = "light"
print config.settings.theme

print "--- Keys with Spaces and Special Characters ---"
var special = {}
special["first name"] = "John"
special["item-count"] = 42
special["path/to/file"] = "/tmp/a.txt"

print special["first name"]
print special["item-count"]
print special["path/to/file"]

print "--- Missing Nested Key Access ---"
var missing = {"a": 1}
print missing["b"]
print missing.c

print "--- Loop Mutations on Dictionary Values ---"
var counts = {"apples": 10, "oranges": 20}
counts["apples"] = counts["apples"] + 5
counts["oranges"] = counts["oranges"] * 2
print counts["apples"]
print counts["oranges"]
