## 2026-07-04 - [Accessibility & Interaction Polish]
**Learning:** Icon-only buttons in the Playground and Navigation lacked descriptive ARIA labels, and the interactive console required manual scrolling to see new output, creating friction for users.
**Action:** Always provide ARIA labels for icon-only buttons and ensure that dynamically updated output containers (like consoles) provide visual confirmation or automatic scrolling to keep the latest information in view.

## 2026-07-08 - [Playground Scroll Synchronization]
**Learning:** When synchronizing scroll position for active elements (like current instruction), using `scrollIntoView` with `block: 'nearest'` is superior to `'start'` or `'center'` as it prevents jarring page jumps when the element is already partially visible, maintaining better spatial orientation for the user.
**Action:** Use `block: 'nearest'` for non-disruptive element tracking in interactive debuggers.
