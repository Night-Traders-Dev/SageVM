# Array push/pop boundary and heterogeneous mutation edge cases

print "--- Initial Array Push & Pop ---"
var arr = []
print "len initial: " + str(len(arr))

push(arr, 100)
push(arr, "hello")
push(arr, nil)
push(arr, [1, 2])
print "len after pushes: " + str(len(arr))

print "pop 1 (array):"
var p1 = pop(arr)
print p1[0]
print p1[1]

print "pop 2 (nil):"
print pop(arr)

print "pop 3 (string):"
print pop(arr)

print "pop 4 (int):"
print pop(arr)

print "len after pops: " + str(len(arr))

print "--- Pop on Empty Array ---"
var empty_pop = pop(arr)
print "pop on empty: " + str(empty_pop)
print "len after empty pop: " + str(len(arr))

print "--- Interleaved Push/Pop in Loop ---"
var stack_arr = []
var i = 0
while i < 5:
    push(stack_arr, i * 10)
    i = i + 1

print "stack len: " + str(len(stack_arr))
var sum_val = 0
while len(stack_arr) > 0:
    sum_val = sum_val + pop(stack_arr)

print "popped sum: " + str(sum_val)
print "final len: " + str(len(stack_arr))
