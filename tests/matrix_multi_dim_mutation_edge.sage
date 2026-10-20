# Test multi-dimensional array creation, index mutation, row/column traversals, and OOB access.

print "--- 2D Matrix Creation and Access ---"
var m2d = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]
print "m2d[0][0]: " + str(m2d[0][0])
print "m2d[1][1]: " + str(m2d[1][1])
print "m2d[2][2]: " + str(m2d[2][2])

print "--- Matrix Nested Element Mutation ---"
m2d[0][0] = 100
m2d[1][1] = 500
m2d[2][2] = 900
print "Mutated m2d[0][0]: " + str(m2d[0][0])
print "Mutated m2d[1][1]: " + str(m2d[1][1])
print "Mutated m2d[2][2]: " + str(m2d[2][2])

print "--- Row Sums via Nested Loops ---"
var r = 0
while r < len(m2d):
    var c = 0
    var row_sum = 0
    while c < len(m2d[r]):
        row_sum = row_sum + m2d[r][c]
        c = c + 1
    print "Row " + str(r) + " sum: " + str(row_sum)
    r = r + 1

print "--- 3D Tensor Access and Mutation ---"
var cube = [
    [[1, 2], [3, 4]],
    [[5, 6], [7, 8]]
]
print "cube[0][1][0]: " + str(cube[0][1][0])
cube[0][1][0] = 333
print "Mutated cube[0][1][0]: " + str(cube[0][1][0])

print "--- Out-Of-Bounds Matrix Access ---"
print "m2d[5] == nil: " + str(m2d[5] == nil)
print "m2d[0][10] == nil: " + str(m2d[0][10] == nil)
