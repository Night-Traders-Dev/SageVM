import sys
print "sys.args type: " + type(sys.args)
print "sys.args is array: " + str(type(sys.args) == "array")
# It should at least contain the script path or be an empty array if not passed
print "sys.args length >= 0: " + str(len(sys.args) >= 0)
