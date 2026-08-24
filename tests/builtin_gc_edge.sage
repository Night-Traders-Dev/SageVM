# Test GC builtins under edge conditions
print "Testing GC builtins..."

# Test gc_disable and gc_enable
gc_disable()
print "GC disabled"

# Allocate some objects while GC is disabled
let a = [1, 2, 3]
let b = {"key": "val"}

# Manually trigger collect while disabled
gc_collect()
print "gc_collect called while disabled"

# Enable GC back
gc_enable()
print "GC enabled"

# Check gc_stats
let stats = gc_stats()
print "gc_stats type: " + type(stats)

# Test gc_collect repeatedly
gc_collect()
gc_collect()
print "Repeated gc_collect complete"
