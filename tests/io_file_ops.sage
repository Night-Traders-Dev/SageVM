import io

print "Testing io module file operations..."

let test_file = "io_test_temp.bin"

# 1. Normal Path: Write a simple array of byte values
var bytes_to_write = [65, 66, 67, 10]
print "Writing bytes..."
var write_res = io.writebytes(test_file, bytes_to_write)
print "Write result: " + str(write_res)

# 2. Normal Path: Read the bytes back
print "Reading bytes..."
var read_bytes = io.readbytes(test_file)
if read_bytes != nil:
    print "Read bytes is not nil"
    print "Type of read_bytes: " + type(read_bytes)
    print "Read bytes length: " + str(len(read_bytes))

    # Documenting Conformance Bug:
    # Indexing a raw BYTES type object returned from io.readbytes in SVM yields nil
    # because get_index logic only handles array, tuple, string, and dict types.
    print "Byte 0 indexing: " + str(read_bytes[0])
else:
    print "Read bytes is nil!"

# 3. Readfile behavior
print "Reading via readfile..."
var read_f = io.readfile(test_file)
if read_f != nil:
    print "Readfile is not nil"
    print "Type of readfile: " + type(read_f)
else:
    print "Readfile is nil!"

# 4. Edge Cases: Non-existent files
print "Reading non-existent file..."
var non_existent = io.readbytes("does_not_exist_xyz.bin")
print "Result for non-existent: " + str(non_existent)

# 5. Edge Cases: Invalid arguments
print "Writing with invalid arguments (nil path):"
print io.writebytes(nil, bytes_to_write)

print "Writing with invalid arguments (nil bytes):"
print io.writebytes(test_file, nil)

print "Reading with invalid arguments (nil path):"
print io.readbytes(nil)

print "Reading with invalid arguments (invalid type):"
print io.readbytes(1234)
