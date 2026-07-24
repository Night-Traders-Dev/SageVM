import sys

# 1. Test existing environment variable
print "TEST_ENV_VAR: " + str(sys.getenv("TEST_ENV_VAR"))

# 2. Test non-existent environment variable
print "NON_EXISTENT: " + str(sys.getenv("NON_EXISTENT_VAR"))

# 3. Test invalid argument type (int instead of string)
print "Invalid arg (int): " + str(sys.getenv(42))
