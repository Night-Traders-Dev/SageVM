proc check_truthy(val, name):
    if not not val:
        print name + " is truthy"
    else:
        print name + " is falsy"

check_truthy(true, "true")
check_truthy(false, "false")
check_truthy(nil, "nil")
check_truthy(1, "1")
check_truthy(0, "0")
check_truthy(-1, "-1")
check_truthy("", "empty string")
check_truthy("hi", "non-empty string")
check_truthy([], "empty array")
check_truthy([1], "non-empty array")
check_truthy({}, "empty dict")
check_truthy({"a": 1}, "non-empty dict")
