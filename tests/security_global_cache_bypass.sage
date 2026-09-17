# Security test: verify inline global cache cannot bypass safe_mode restrictions on internal names

var i = 0
while i < 3:
    let secret = __secret_internal
    if secret == nil:
        print "GET_GLOBAL internal read blocked"
    else:
        print "VULNERABLE: GET_GLOBAL internal read leaked"
    i = i + 1

var j = 0
while j < 3:
    __secret_internal = 999
    j = j + 1

print "SET_GLOBAL internal write loop complete"
