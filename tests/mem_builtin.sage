import mem

print "Testing mem module..."
var ptr = mem.alloc(8)
if ptr != nil:
    print "Allocated 8 bytes"
    # Note: mem.size, mem.write, mem.read might be stubs or have issues
    # but we will try to call them to see what happens.

    print "Size: " + str(mem.size(ptr))

    # Try writing/reading (assuming 4-byte i32 for simplicity if it works like C)
    mem.write(ptr, 0, "i32", 1234)
    var val = mem.read(ptr, 0, "i32")
    print "Read value: " + str(val)

    mem.free(ptr)
    print "Freed"
else:
    print "mem.alloc returned nil"
