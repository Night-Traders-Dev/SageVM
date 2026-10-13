print "--- For Over range ---"
# The counter rides on the operand stack for the whole loop and the loop head
# is translated once, so a fresh register per increment left the head
# re-reading a register nobody wrote to and the loop indexed at 0 forever.

for i in range(3):
    print i

print "--- For Over A Literal ---"
for v in [10, 20, 30]:
    print v

print "--- Body Arithmetic ---"
for i in range(4):
    print i * 3

print "--- Strings ---"
for s in ["a", "b"]:
    print s

print "--- Empty Body ---"
for i in range(3):
    pass
print "done"

print "--- Statement Inside The Body ---"
# set_global leaves its value on the stack and the bytecode pops it. If the
# translator also popped, it consumed an extra entry per statement and walked
# off the counter into the iterable.
var seen = 0
for i in range(3):
    seen = i
    print seen

print "--- Accumulate ---"
# A `for` loop wraps its body in push_env/pop_env, and those used to swap the
# globals dict. So the total was wiped on entry and restored to its pre-loop
# value on the way out, and each iteration read it back as zero.
var total = 0
for i in range(5):
    total = total + i
print total

print "--- Global Survives The Loop ---"
var seed = 7
for i in range(3):
    print seed
print seed

print "--- While Still Works ---"
var k = 0
while k < 3:
    print k
    k = k + 1