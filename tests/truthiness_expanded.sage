proc check(val, name):
    if val:
        print name + " is truthy"
    else:
        print name + " is falsy"

check(0, "0")
check(nil, "nil")
check(false, "false")
check("", "empty string")
check([], "empty array")
check({}, "empty dict")
check(1, "1")
check(-1, "-1")
check("hi", "non-empty string")
check([1], "non-empty array")
check({"a": 1}, "non-empty dict")
