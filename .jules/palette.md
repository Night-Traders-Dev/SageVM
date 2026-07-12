## 2026-07-04 - [Accessibility & Interaction Polish]
**Learning:** Icon-only buttons in the Playground and Navigation lacked descriptive ARIA labels, and the interactive console required manual scrolling to see new output, creating friction for users.
**Action:** Always provide ARIA labels for icon-only buttons and ensure that dynamically updated output containers (like consoles) provide visual confirmation or automatic scrolling to keep the latest information in view.

## 2026-07-08 - [Playground Scroll Synchronization]
**Learning:** When synchronizing scroll position for active elements (like current instruction), using `scrollIntoView` with `block: 'nearest'` is superior to `'start'` or `'center'` as it prevents jarring page jumps when the element is already partially visible, maintaining better spatial orientation for the user.
**Action:** Use `block: 'nearest'` for non-disruptive element tracking in interactive debuggers.

## 2026-07-16 - [Comprehensive Accessibility Audit]
**Learning:** Interactive components often lack proper state indicators and keyboard support beyond basic buttons. Adding `aria-pressed` to tab-like filters and converting interactive `div` elements to use `role="button"` with `tabIndex` and `onKeyDown` handlers ensures that the rich documentation features are navigable for all users.
**Action:** Always audit custom interactive components (filters, cards, toggles) for ARIA states and keyboard parity.
