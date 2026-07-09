# Test OP_EXEC_AST_STMT via exec()
# The VM falls back to host sys.exec for non-lowered code
# In the current implementation, exec() emits OP_EXEC_AST_STMT
# which calls host sys.exec(ast_code).
# However, host sys.exec seems to be restricted or non-functional in this environment.
# We will keep the test but comment that it's failing.

print "Testing exec..."
exec("print 'Hello from exec'")
