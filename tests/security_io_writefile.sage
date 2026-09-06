let b_write = "__builtin_io_writefile"
let res = b_write("tmp_test_file.txt", "hello")
print "direct writefile result: " + str(res)

let b_read = "__builtin_io_readfile"
let r_res = b_read("tmp_test_file.txt")
print "direct readfile result: " + str(r_res)
