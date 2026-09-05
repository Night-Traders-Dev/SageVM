# Security test for SRVM memory and FFI builtin restriction under safe mode

let mem_alloc_fn = "__builtin_mem_alloc"
let res = mem_alloc_fn(1024)
if res == nil:
    print "mem_alloc blocked"

let ffi_open_fn = "__builtin_ffi_open"
let f_res = ffi_open_fn("libm.so")
if f_res == nil:
    print "ffi_open blocked"

let struct_def_fn = "__builtin_struct_def"
let s_res = struct_def_fn("Point")
if s_res == nil:
    print "struct_def blocked"
