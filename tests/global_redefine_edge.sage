# Test global variable operations (OP_DEFINE_GLOBAL, OP_SET_GLOBAL, OP_GET_GLOBAL),
# global cache invalidation, global updates inside functions and loops,
# block-scoped definitions, and global collection mutation.

var g_val = 10
var g_name = "Alpha"
var g_list = [100, 200]
var g_dict = {"key": "val1"}

print "--- Initial Globals ---"
print "g_val: " + str(g_val)
print "g_name: " + str(g_name)
print "g_list len: " + str(len(g_list))
print "g_dict key: " + str(g_dict["key"])

proc modify_globals():
    g_val = 99
    g_name = "Beta"
    push(g_list, 300)
    g_dict["key"] = "val2"
    g_dict["new_key"] = "val3"

print "--- Modify via Function ---"
modify_globals()
print "g_val: " + str(g_val)
print "g_name: " + str(g_name)
print "g_list len: " + str(len(g_list))
print "g_dict key: " + str(g_dict["key"])
print "g_dict new_key: " + str(g_dict["new_key"])

proc loop_modify_globals():
    var i = 0
    while i < 3:
        g_val = g_val + 10
        i = i + 1

print "--- Modify via Loop in Function ---"
loop_modify_globals()
print "g_val after loop: " + str(g_val)

print "--- Conditional Global Reassignment ---"
if true:
    g_name = "Gamma"
    g_val = 500

print "g_val conditional: " + str(g_val)
print "g_name conditional: " + str(g_name)
