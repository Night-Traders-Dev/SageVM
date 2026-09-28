print "=== Collection Indexing Edge Cases ==="

print "1. Array Indexing & Mutation:"
let arr = [10, 20, 30]
print arr[0]
print arr[1 + 1]
print arr[5]

arr[1] = 200
print arr[1]

print "2. Matrix 2D Indexing & Mutation:"
let matrix = [[1, 2], [3, 4]]
print matrix[0][1]
print matrix[1][0]
matrix[1][0] = 99
print matrix[1][0]

print "3. Dictionary Key Access & Non-String Keys:"
let d = {"name": "Sage"}
d[100] = "numeric_key"
print d["name"]
print d["unknown"]
print d[100]

d["name"] = "SageVM"
d[200] = "another_key"
print d["name"]
print d[200]

print "4. String Indexing:"
let s = "SageVM"
print s[0]
print s[5]
print s[10]

print "5. Nested Collections Mutation:"
let nested = {"items": [10, 20, 30]}
print nested["items"][1]
nested["items"][1] = 999
print nested["items"][1]
