# Test collection builtin operations
let arr = [1, 2, 3]
push(arr, 4)
print len(arr)
print arr[3]
let last = pop(arr)
print last
print len(arr)

let d = {"a": 1, "b": 2}
print dict_has(d, "a")
print dict_has(d, "c")
let keys = dict_keys(d)
print len(keys)
