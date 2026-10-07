# Test that calling I/O and sys execution builtins with missing or nil arguments is handled gracefully without host exceptions

print "Testing __builtin_io_readfile with no args:"
let rf = "__builtin_io_readfile"
print rf()

print "Testing __builtin_io_readfile with nil:"
print rf(nil)

print "Testing __builtin_io_readbytes with no args:"
let rb = "__builtin_io_readbytes"
print rb()

print "Testing __builtin_io_writefile with missing args:"
let wf = "__builtin_io_writefile"
print wf()
print wf("test.txt")

print "Testing __builtin_io_writebytes with missing args:"
let wb = "__builtin_io_writebytes"
print wb()
print wb("test.bin")

print "Testing __builtin_sys_exec with no args:"
let se = "__builtin_sys_exec"
print se()

print "Testing __builtin_sys_system with no args:"
let ss = "__builtin_sys_system"
print ss()
