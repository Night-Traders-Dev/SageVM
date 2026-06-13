var d = {"name": "Sage", "version": 1.0}
print("len=" + str(len(d)))
print("name=" + str(d["name"]))
d["version"] = 1.1
print("version=" + str(d["version"]))
d["new_key"] = "new_val"
print("new_key=" + str(d["new_key"]))

# Edge case: missing key
# Current behavior: returns nil (which is then converted to string "nil")
print("missing=" + str(d["missing"]))
