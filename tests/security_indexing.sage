var d = {"__internal": "secret", "public": "visible"}

# In safe mode, access to __ prefixed keys should return nil
print "Internal: " + str(d["__internal"])
print "Public: " + str(d["public"])

# In safe mode, assignment to __ prefixed keys should be blocked
d["__internal"] = "changed"
print "Internal after set: " + str(d["__internal"])

# Regular keys should still work
d["public"] = "modified"
print "Public after set: " + str(d["public"])
