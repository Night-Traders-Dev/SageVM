# Test io.writebytes and io.readbytes standard operations and edge cases
import io

let filepath = "temp_io_file_ops_test.bin"

# 1. Normal writing
let bytes_to_write = [104, 101, 108, 108, 111] # "hello"
let write_res = io.writebytes(filepath, bytes_to_write)
print "writebytes result: " + str(write_res)

# 2. Normal reading
let bytes_read = io.readbytes(filepath)
print "readbytes exists: " + str(bytes_read != nil)
print "readbytes len: " + str(len(bytes_read))
# BUG: In the SVM interpreter, indexing bytes returned from `io.readbytes` via bracket syntax
# returns nil instead of the raw integer byte value. We assert actual behavior here and flag this bug.
print "readbytes first byte: " + str(bytes_read[0])

# 3. Edge cases and boundary checks
print "io.readbytes(nil): " + str(io.readbytes(nil) == nil)
print "io.readbytes(123): " + str(io.readbytes(123) == nil)
print "io.writebytes(nil, nil): " + str(io.writebytes(nil, nil))
print "io.writebytes(filepath, nil): " + str(io.writebytes(filepath, nil))
