## 2026-06-13 - Resource Exhaustion (DoS) in VM via Deep Recursion
**Vulnerability:** The SageVM interpreter lacked internal limits for stack depth and call depth. A malicious or buggy script could cause deep recursion, leading to memory exhaustion or a crash of the host SageLang interpreter (CWE-674).
**Learning:** Virtual machines implemented in high-level languages must explicitly manage their own resource boundaries, as they do not automatically inherit the underlying language's safety limits in a way that prevents DoS of the host.
**Prevention:** Always implement explicit depth checks for stacks, call stacks, and recursive structures in VM implementations.
