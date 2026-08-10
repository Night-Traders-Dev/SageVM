import sys

print "sys.exec restricted:"
var res1 = sys.exec("echo shouldn't run")
print "res1: " + str(res1)

print "sys.system restricted:"
var res2 = sys.system("echo shouldn't run")
print "res2: " + str(res2)
