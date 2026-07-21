# Test native io module bridging
# Bug: Native functions/modules evaluation type mismatch bug in SVM backend.
# Under safe mode, the io module is restricted (this test runs under normal/non-safe mode).
import io

print "io exists: " + str(io != nil)
var data = io.readbytes("non_existent_file.txt")
print "non-existent file data: " + str(data)
