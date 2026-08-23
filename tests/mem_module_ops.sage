import mem

print "Testing mem module edge cases..."
print "Mem alloc 0: " + str(mem.alloc(0) != nil)
print "Mem alloc negative: " + str(mem.alloc(-1))
print "Mem alloc nil: " + str(mem.alloc(nil))

var ptr = mem.alloc(16)
if ptr != nil:
    print "Allocated 16 bytes"
    print "Mem size valid: " + str(mem.size(ptr))
    print "Mem read OOB/nil format: " + str(mem.read(ptr, 0, nil))
    print "Mem write nil data: " + str(mem.write(ptr, 0, nil, nil))
    mem.free(ptr)
    print "Freed"

print "Mem free nil: " + str(mem.free(nil))
print "Mem size nil: " + str(mem.size(nil))
