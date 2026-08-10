# Test GPU poll events and mouse pos module operations
import gpu

# Normal behavior
print "gpu.poll_events(): " + str(gpu.poll_events() == nil)
let pos = gpu.mouse_pos()
print "gpu.mouse_pos() type: " + type(pos)
print "pos.x: " + str(pos["x"])
print "pos.y: " + str(pos["y"])

# Edge cases / boundary: check if coordinates are numbers
print "pos.x is number: " + str(type(pos["x"]) == "number")
print "pos.y is number: " + str(type(pos["y"]) == "number")
