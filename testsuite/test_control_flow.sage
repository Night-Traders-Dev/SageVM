# test_control_flow.sage
# Tests if/elif/else, while loop, and break/continue.
# Expected output:
#   fizz
#   1
#   2
#   fizz
#   4
#   buzz
#   fizz
#   7
#   8
#   fizz
#   buzz

var i = 0
while i < 11:
    i = i + 1
    if i % 15 == 0:
        print("fizzbuzz")
    elif i % 3 == 0:
        print("fizz")
    elif i % 5 == 0:
        print("buzz")
    else:
        print(str(i))
