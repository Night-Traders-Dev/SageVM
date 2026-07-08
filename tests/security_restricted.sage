import sys
import io
import net
import thread
import gpu
import ml_native
import mem
import ffi

print "sys restricted: " + str(sys == nil)
print "io restricted: " + str(io == nil)
print "net restricted: " + str(net == nil)
print "thread restricted: " + str(thread == nil)
print "gpu restricted: " + str(gpu == nil)
print "ml_native restricted: " + str(ml_native == nil)
print "mem restricted: " + str(mem == nil)
print "ffi restricted: " + str(ffi == nil)
