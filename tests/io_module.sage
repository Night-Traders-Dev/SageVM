import io

print "Testing native io module bridging..."
let test_file = "temp_io_test_file.txt"

# Ensure we start fresh
if io.exists(test_file):
    io.remove(test_file)

# Write to file
io.writefile(test_file, "Hello from SageVM!")
print "File exists after write: " + str(io.exists(test_file))

# Read from file
let content = io.readfile(test_file)
print "File content: " + content

# Get filesize
print "File size: " + str(io.filesize(test_file))

# Clean up
io.remove(test_file)
print "File exists after remove: " + str(io.exists(test_file))

# Edge case: read nonexistent file
let nonexistent = io.readfile("this_file_does_not_exist_xyz.txt")
print "Non-existent file content: " + str(nonexistent)

# Edge case: checking exists on a non-existent file
print "Exists on non-existent: " + str(io.exists("this_file_does_not_exist_xyz.txt"))
