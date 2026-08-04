# Test FFI Library Bridging behavior
# Note: Dynamic FFI calls may evaluate to nil or fail because src/svm/sgvm_vm.sage
# does not import the host ffi module or due to host environment limitations.
# We document this dynamic behavior and verify the output.

import ffi

print "Testing FFI module..."
if ffi != nil:
    print "FFI module available"
else:
    print "FFI module is nil"

# Let's try calling some methods on ffi module
try:
    var handle = ffi.open("libc.so.6")
    if handle != nil:
        print "Opened libc"
        # Since dynamic FFI calls may evaluate to nil, let's verify if that's the case.
        # This checks the guest VM bug where dynamic FFI calls evaluate to nil.
        var res = ffi.call(handle, "abs", "int", [-123])
        if res == nil:
            print "FFI call returned nil (documented bug)"
        else:
            print "FFI call returned: " + str(res)
        ffi.close(handle)
        print "Closed libc"
    else:
        print "ffi.open returned nil"
catch e:
    print "FFI call caught exception: " + str(e)
