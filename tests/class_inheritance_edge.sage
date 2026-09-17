# Test multi-level class inheritance, method overriding, and missing method resolution.

class BaseComponent:
    proc init(self, id):
        self.id = id

    proc describe(self):
        print "BaseComponent ID: " + str(self.id)

    proc base_only(self):
        print "Base only method executed for ID: " + str(self.id)

class UIElement(BaseComponent):
    proc init(self, id, visible):
        self.id = id
        self.visible = visible

    proc describe(self):
        print "UIElement ID: " + str(self.id) + ", visible: " + str(self.visible)

class Button(UIElement):
    proc init(self, id, visible, label):
        self.id = id
        self.visible = visible
        self.label = label

    proc describe(self):
        print "Button ID: " + str(self.id) + " ['" + str(self.label) + "'], visible: " + str(self.visible)

    proc click(self):
        print "Button " + str(self.label) + " clicked!"

print "--- Multi-level Inheritance & Overriding ---"
var b = Button(101, true, "Submit")
b.describe()
b.click()

print "--- Grandparent Method Inheritance ---"
b.base_only()

print "--- Parent Class Instance ---"
var elem = UIElement(202, false)
elem.describe()
elem.base_only()

print "--- Non-existent Property Edge Case ---"
print "elem.non_existent == nil: " + str(elem.non_existent == nil)
