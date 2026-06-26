## 2025-06-13 - [CLI Accessibility and Feedback]
**Learning:** CLI tools should follow standard conventions like --help and --version to be accessible and discoverable. Visual feedback (emojis) and specific error messages (including filenames) significantly improve the user experience and debuggability.
**Action:** Always include --help and --version in CLI tools, and ensure error messages are context-aware.

## 2026-06-18 - [CLI Output Filename Hygiene]
**Learning:** Automatically stripping source file extensions (like .sage) when generating default output filenames prevents redundant extensions (e.g., .sage.sgvm), leading to a cleaner and more professional-feeling CLI experience.
**Action:** When deriving output filenames from inputs in CLI tools, always check for and strip known source extensions.

## 2026-06-20 - [Contextual CLI Tips for Source Files]
**Learning:** Users often attempt to execute source files (.sage) directly with the VM runner (sagevm run), leading to confusing "Invalid Header" errors.
**Action:** Implement extension-based detection in the CLI to intercept these attempts and provide a clear "Try compiling first" tip.

## 2026-06-21 - [Colorized CLI Feedback]
**Learning:** Colorizing CLI output significantly improves the scannability and "feel" of a tool. Errors that stand out in red and success messages in green provide immediate, pre-attentive feedback that makes the tool feel more responsive and professional.
**Action:** Always use a consistent color palette (Red for errors, Green for success, Yellow for tips, Cyan for headers) in CLI tools to improve user navigation and feedback clarity.

## 2026-06-22 - [Smart CLI Path Suggestions and Artifact Feedback]
**Learning:** Providing smart path suggestions when a file is not found (e.g., checking for .sgvm or .sgrv extensions) significantly reduces user friction and makes the tool feel more helpful. Additionally, reporting the size of generated binaries provides immediate, valuable feedback about the result of a compilation.
**Action:** In CLI tools, implement "Did you mean?" suggestions for common file extensions and always report artifact metadata (like size) on successful generation.

## 2026-06-24 - [CLI Verification Consistency]
**Learning:** UX polish must be applied consistently across all command handlers; "partial polish" (e.g., only in the 'run' command) makes neglected commands feel broken by comparison. Centralizing verification logic prevents crashes and ensures a high-quality experience regardless of the user's entry point.
**Action:** Refactor cross-cutting UX concerns (like file verification and suggestions) into shared helpers to ensure uniform quality across the entire CLI surface area.

## 2026-06-25 - [Color Suppression for Accessibility and Compatibility]
**Learning:** Hardcoded ANSI escape sequences can cause readability issues for users with specific color sensitivities or in environments that don't support color (like dumb terminals or certain CI logs). Respecting NO_COLOR and TERM=dumb is a standard but often overlooked UX requirement for CLI tools.
**Action:** Always check for NO_COLOR and TERM environment variables before emitting ANSI color codes in CLI applications.

## 2026-06-26 - [Actionable Post-Command Guidance]
**Learning:** Guiding the user to the next logical step in their workflow (e.g., suggesting 'run' after a successful 'compile') reduces cognitive load and creates a "delightful" flow. Explicitly printing the exact command they need makes the tool feel smarter and more helpful.
**Action:** When a command generates an artifact, always provide a colorized example of how to use or execute that artifact in the next step.

## 2026-06-26 - [Preventing Common Command/File Mismatches]
**Learning:** Users sometimes lose track of a file's state (source vs. binary) and attempt incompatible operations (like compiling an already compiled binary).
**Action:** Implement symmetric proactive checks: suggest 'compile' when running a source file, and suggest 'run' when compiling a binary file (detected via extension or magic bytes).
