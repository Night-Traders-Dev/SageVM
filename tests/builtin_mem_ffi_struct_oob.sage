# Test that calling memory, FFI, and struct builtins with missing or nil arguments is handled gracefully without host exceptions

print "Testing __builtin_mem_alloc with no args:"
let ma = "__builtin_mem_alloc"
print ma()

print "Testing __builtin_mem_free with no args:"
let mf = "__builtin_mem_free"
print mf()

print "Testing __builtin_mem_read with missing args:"
let mr = "__builtin_mem_read"
print mr()
print mr(0, 0)

print "Testing __builtin_mem_write with missing args:"
let mw = "__builtin_mem_write"
print mw()
print mw(0, 0, 0)

print "Testing __builtin_mem_size with no args:"
let ms = "__builtin_mem_size"
print ms()

print "Testing __builtin_ffi_open with no args:"
let fo = "__builtin_ffi_open"
print fo()

print "Testing __builtin_ffi_close with no args:"
let fc = "__builtin_ffi_close"
print fc()

print "Testing __builtin_ffi_call with missing args:"
let fcall = "__builtin_ffi_call"
print fcall()

print "Testing __builtin_struct_def with no args:"
let sd = "__builtin_struct_def"
print sd()

print "Testing __builtin_struct_new with no args:"
let sn = "__builtin_struct_new"
print sn()

print "Testing __builtin_struct_get with missing args:"
let sg = "__builtin_struct_get"
print sg()

print "Testing __builtin_struct_set with missing args:"
let ss = "__builtin_struct_set"
print ss()

print "Testing __builtin_struct_size with no args:"
let ssize = "__builtin_struct_size"
print ssize()
