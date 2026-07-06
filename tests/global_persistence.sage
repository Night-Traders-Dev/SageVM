var g_val = 100

proc modify_global():
    g_val = 200

proc shadow_global():
    let g_val = 300
    print "Shadowed: " + str(g_val)

print "Initial: " + str(g_val)
modify_global()
print "After modification: " + str(g_val)
shadow_global()
print "After shadowing call: " + str(g_val)
