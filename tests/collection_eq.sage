# Collection Equality (Deep Equality)
# BUG: Dictionary equality comparison currently fails in the SVM backend,
# always returning false even for identical dictionaries.

print "Array equality:"
print [1, 2, 3] == [1, 2, 3]
print [1, 2, 3] == [1, 2, 4]
print [1, [2, 3]] == [1, [2, 3]]
print [1, [2, 3]] == [1, [2, 4]]

print "Dict equality:"
print {"a": 1, "b": 2} == {"a": 1, "b": 2}
print {"a": 1, "b": 2} == {"b": 2, "a": 1}
print {"a": 1, "b": 2} == {"a": 1, "b": 3}
print {"a": {"b": 1}} == {"a": {"b": 1}}

print "Mixed equality:"
print {"a": [1, 2]} == {"a": [1, 2]}
print {"a": [1, 2]} == {"a": [1, 3]}

print "Type mismatch:"
print [1, 2] == {"a": 1}
print [1, 2] == "not an array"
