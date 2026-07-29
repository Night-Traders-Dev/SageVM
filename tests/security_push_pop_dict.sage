# Create a standard dictionary (unprotected)
var normal_dict = {"value": 42}
normal_dict["key"] = 100
print "Unprotected dict mutated via indexing: " + str(normal_dict["key"])

# Verify standard list/array push/pop works in safe mode
var normal_list = [1, 2, 3]
push(normal_list, 4)
print "Unprotected list after push: " + str(len(normal_list))
let popped = pop(normal_list)
print "Popped value: " + str(popped)

# Verify direct builtin push/pop block on protected dicts/modules
let push_fn = "__builtin_push"
let pop_fn = "__builtin_pop"

# Protected dictionary mimicking a module/builtin wrapper
var protected_dict = {"__type__": "module", "pi": 3.14}
push_fn(protected_dict, "extra")
pop_fn(protected_dict)
