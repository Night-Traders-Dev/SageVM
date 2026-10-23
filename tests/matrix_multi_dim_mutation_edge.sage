print "--- 2D Matrix Creation and Element Mutation ---"
var matrix = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]

print "matrix[1][1] initial: " + str(matrix[1][1])
matrix[1][1] = 99
print "matrix[1][1] mutated: " + str(matrix[1][1])

print "--- Row Sums ---"
var r = 0
while r < len(matrix):
    var row = matrix[r]
    var row_sum = 0
    var c = 0
    while c < len(row):
        row_sum = row_sum + row[c]
        c = c + 1
    print "row " + str(r) + " sum: " + str(row_sum)
    r = r + 1

print "--- Column Sums ---"
var col_idx = 0
while col_idx < 3:
    var col_sum = 0
    var row_idx = 0
    while row_idx < len(matrix):
        col_sum = col_sum + matrix[row_idx][col_idx]
        row_idx = row_idx + 1
    print "col " + str(col_idx) + " sum: " + str(col_sum)
    col_idx = col_idx + 1

print "--- 3D Tensor Element Access & Mutation ---"
var tensor = [
    [
        [10, 20],
        [30, 40]
    ],
    [
        [50, 60],
        [70, 80]
    ]
]

print "tensor[1][0][1] initial: " + str(tensor[1][0][1])
tensor[1][0][1] = 999
print "tensor[1][0][1] mutated: " + str(tensor[1][0][1])

print "--- Out of Bounds Index Handling ---"
print "matrix[0][5] oob: " + str(matrix[0][5])
print "matrix[10] oob: " + str(matrix[10])
