import gpu

print "Testing gpu module operations..."

print "gpu exists: " + str(gpu != nil)
print "gpu.poll_events exists: " + str(gpu.poll_events != nil)
print "gpu.mouse_pos exists: " + str(gpu.mouse_pos != nil)

print "Calling poll_events..."
var poll_res = gpu.poll_events()
print "poll_events result: " + str(poll_res)

print "Calling mouse_pos..."
var mouse_res = gpu.mouse_pos()
if mouse_res != nil:
    print "mouse_pos is a dictionary: " + str(type(mouse_res) == "dict")
    print "mouse_pos x: " + str(mouse_res["x"])
    print "mouse_pos y: " + str(mouse_res["y"])
else:
    print "mouse_pos is nil!"
