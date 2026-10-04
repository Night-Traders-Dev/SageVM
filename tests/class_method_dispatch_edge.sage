# Test class instantiation, method dispatch, method chaining, self calls, dynamic properties, and missing property/method access

print "--- Multi-parameter constructor and self method calls ---"
class Counter:
    proc init(self, start, step):
        self.count = start
        self.step = step

    proc add_step(self):
        self.count = self.count + self.step
        return self

    proc add_custom(self, val):
        self.count = self.count + val
        return self

    proc value(self):
        return self.count

var c = Counter(10, 5)
print "Initial value: " + str(c.value())
c.add_step()
print "After add_step: " + str(c.value())

print "--- Method chaining returning self ---"
c.add_step().add_custom(20).add_step()
print "After chain: " + str(c.value())

print "--- Dynamic property addition and reassignment ---"
c.label = "counter_A"
print "Label: " + c.label
c.label = nil
print "Label after nil re-assignment == nil: " + str(c.label == nil)

print "--- Missing property and missing method calls ---"
print "Missing property == nil: " + str(c.non_existent_prop == nil)
var res = c.non_existent_method()
print "Missing method call result: " + str(res)
