import io

# Test calling writefile on restricted io module in safe mode
try:
    io.writefile("tmp_test_file.txt", "hello")
catch e:
    print "Error caught"

# Test direct builtin execution under safe mode
let b_write = "__builtin_io_writefile"
print "builtin writefile direct result: " + str(b_write)
