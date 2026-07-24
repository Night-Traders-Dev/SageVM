## 2026-07-04 - [Accessibility & Interaction Polish]
**Learning:** Icon-only buttons in the Playground and Navigation lacked descriptive ARIA labels, and the interactive console required manual scrolling to see new output, creating friction for users.
**Action:** Always provide ARIA labels for icon-only buttons and ensure that dynamically updated output containers (like consoles) provide visual confirmation or automatic scrolling to keep the latest information in view.

## 2026-07-08 - [Playground Scroll Synchronization]
**Learning:** When synchronizing scroll position for active elements (like current instruction), using `scrollIntoView` with `block: 'nearest'` is superior to `'start'` or `'center'` as it prevents jarring page jumps when the element is already partially visible, maintaining better spatial orientation for the user.
**Action:** Use `block: 'nearest'` for non-disruptive element tracking in interactive debuggers.

## 2026-07-16 - [Comprehensive Accessibility Audit]
**Learning:** Interactive components often lack proper state indicators and keyboard support beyond basic buttons. Adding `aria-pressed` to tab-like filters and converting interactive `div` elements to use `role="button"` with `tabIndex` and `onKeyDown` handlers ensures that the rich documentation features are navigable for all users.
**Action:** Always audit custom interactive components (filters, cards, toggles) for ARIA states and keyboard parity.

## 2026-07-15 - [Accessible Search & Interactive Reference]
**Learning:** For interactive documentation like the Opcode Reference, accessibility must extend beyond static labels. Implementing `aria-pressed` for filters and `aria-expanded` with keyboard listeners for cards ensures that complex instruction sets remain navigable and informative for users relying on assistive technology or keyboard-only input.
**Action:** Ensure search inputs have clear `aria-label` and interactive grid items support standard keyboard triggers (Enter/Space) with visual focus rings.

## 2026-07-17 - [Accessible Range Inputs & Custom Controls]
**Learning:** Interactive range sliders and file upload inputs must have explicit ARIA labels. Relying solely on flanking text span elements or visual titles is insufficient for screen readers to convey control purpose.
**Action:** Always verify that every custom input type (including hidden file inputs wrapped in labels and range sliders) has a dedicated `aria-label` describing its exact function.

## 2026-07-18 - [Accessible Interactive Toggles & Submodule Management]
**Learning:** Custom interactive components like the Globals panel header in the playground require full keyboard navigation (role="button", tabIndex={0}, and keydown event handlers) and proper ARIA states (aria-pressed/aria-expanded) to ensure compatibility with screen readers. Furthermore, since the documentation resides in a git submodule 'docs/site', changes must be committed in the sub-repository before updating the parent repository's submodule pointer.
**Action:** Always implement keyboard listeners (Space & Enter) and ARIA states for collapsible panels, and ensure submodule commits are resolved first in parent-submodule setups.

## 2026-07-23 - [Search & Filter Recovery Patterns]
**Learning:** In interactive doc sites, search/filter systems can easily trap keyboard users in "zero results" states if there isn't a keyboard-accessible, fast recovery action (such as a clear button or reset button) that focuses back or resets state gracefully. Providing a fallback call-to-action button in empty states improves task flow and prevents navigation dead-ends.
**Action:** Always include a "Reset" or "Clear" CTA in empty search/filter states to ensure smooth recovery.
