import sys

# Test sys.exit()
# BUG: Currently sys.exit() doesn't immediately halt the VM execution in the guest-to-host bridge.
# Expected behavior: Program should stop immediately after sys.exit() and not print "Should not print"
print "Before exit"
sys.exit(0)
print "Should not print"
