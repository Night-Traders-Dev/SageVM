## 2025-06-13 - [CLI Accessibility and Feedback]
**Learning:** CLI tools should follow standard conventions like --help and --version to be accessible and discoverable. Visual feedback (emojis) and specific error messages (including filenames) significantly improve the user experience and debuggability.
**Action:** Always include --help and --version in CLI tools, and ensure error messages are context-aware.

## 2026-06-18 - [CLI Output Filename Hygiene]
**Learning:** Automatically stripping source file extensions (like .sage) when generating default output filenames prevents redundant extensions (e.g., .sage.sgvm), leading to a cleaner and more professional-feeling CLI experience.
**Action:** When deriving output filenames from inputs in CLI tools, always check for and strip known source extensions.
