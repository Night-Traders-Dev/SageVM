## 2026-07-04 - [Accessibility & Interaction Polish]
**Learning:** Icon-only buttons in the Playground and Navigation lacked descriptive ARIA labels, and the interactive console required manual scrolling to see new output, creating friction for users.
**Action:** Always provide ARIA labels for icon-only buttons and ensure that dynamically updated output containers (like consoles) provide visual confirmation or automatic scrolling to keep the latest information in view.

## 2026-07-08 - [Playground Scroll Synchronization]
**Learning:** When synchronizing scroll position for active elements (like current instruction), using `scrollIntoView` with `block: 'nearest'` is superior to `'start'` or `'center'` as it prevents jarring page jumps when the element is already partially visible, maintaining better spatial orientation for the user.
**Action:** Use `block: 'nearest'` for non-disruptive element tracking in interactive debuggers.

## 2026-07-12 - [Playground Auto-Scroll & A11y]
**Learning:** Automatically scrolling the console and active bytecode instructions significantly improves the "flow" of execution tracking. Adding ARIA labels to icon-only buttons in the Playground ensures that these features are accessible to screen reader users, who otherwise would only hear "button".
**Action:** Combine interaction polish (auto-scroll) with accessibility (ARIA labels) when enhancing interactive components.

## 2026-07-13 - [Playground Interaction & Accessibility Sync]
**Learning:** Combining scroll-into-view for active bytecode and auto-scrolling for console output ensures the user never loses context during execution. Converting clickable divs to semantic buttons with aria-expanded/aria-label provides a robust experience for screen readers and keyboard users.
**Action:** Always prefer semantic buttons over clickable divs for toggles, and sync scroll states in complex interactive debuggers.
