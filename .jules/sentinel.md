## 2026-06-13 - Resource Exhaustion (DoS) in VM via Deep Recursion
**Vulnerability:** The SageVM interpreter lacked internal limits for stack depth and call depth. A malicious or buggy script could cause deep recursion, leading to memory exhaustion or a crash of the host SageLang interpreter (CWE-674).
**Learning:** Virtual machines implemented in high-level languages must explicitly manage their own resource boundaries, as they do not automatically inherit the underlying language's safety limits in a way that prevents DoS of the host.
**Prevention:** Always implement explicit depth checks for stacks, call stacks, and recursive structures in VM implementations.

## 2026-06-15 - Command Injection in compiler via unvalidated file paths
**Vulnerability:** The SGVMC compiler constructed shell commands using raw input filenames and executed them via 'sys.exec' (which calls the C 'system()' function). A maliciously named file could execute arbitrary commands on the host system.
**Learning:** Even internal toolchains must treat file paths as untrusted input when they are passed to shell-executing functions. Traditional path sanitization is insufficient if the string is eventually evaluated by a shell.
**Prevention:** Always validate or sanitize input strings before concatenating them into shell commands, or preferably, use argument-vector based execution APIs that bypass the shell.

## 2026-06-20 - Sandbox Escape via Direct Builtin Calls
**Vulnerability:** The MetalVM sandbox restricted access to sensitive modules (io, mem, ffi, struct) by removing them from the global namespace in `safe_mode`. However, it failed to restrict direct calls to the underlying internal builtin functions (e.g., `__builtin_mem_alloc`, `__builtin_struct_def`) when called by name by a guest program.
**Learning:** Sandboxing by namespace restriction is insufficient if the VM exposes a flat execution bridge for internal builtins. Security checks must be applied at the point of execution (the dispatcher) for all sensitive operations.
**Prevention:** Always implement explicit security checks within the VM's builtin call dispatcher, independent of how the function was resolved or accessed by the guest program.

## 2026-06-23 - Sandbox Escape via Module Hijacking
**Vulnerability:** The MetalVM allowed guest code to mutate module wrappers and host objects via 'OP_SET_PROPERTY' and 'OP_SET_INDEX'. In 'safe_mode', an attacker could overwrite module functions (e.g., math.sqrt) with malicious logic or potentially reach the underlying host module and hijack its functionality.
**Learning:** Preventing access to sensitive modules is not enough if the VM allows mutation of shared objects that are still reachable. Sandbox boundaries must include write-protection for all host-provided structures.
**Prevention:** Implement strict write-protection for modules, module wrappers, and host objects within the VM's property and index assignment handlers.

## 2026-06-25 - Resource Exhaustion (DoS) in SRVM (RISC-V VM)
**Vulnerability:** The SRVM interpreter lacked limits for call stack depth, try-handler depth, and array allocation size. A malicious script could cause host memory exhaustion or stack overflow via deep recursion or massive array creation (CWE-770).
**Learning:** Resource limits must be consistently applied across all execution engines in a multi-architecture VM substrate. Porting an architecture (like RISC-V) often involves porting its security boundaries as well.
**Prevention:** Standardize resource limit constants across all VM implementations and enforce them in core dispatchers and allocation handlers.

## 2026-06-25 - Hardening the RISC-V VM Sandbox
**Vulnerability:** The Sage RISC-V VM (SRVM) lacked the mutation-protection sandbox features present in the SVM backend. Guest code could mutate host-provided modules or objects even when `--safe` was ostensibly requested.
**Learning:** In a multi-backend system, security features like sandboxing must be treated as first-class citizens and ported with parity across all execution engines to avoid "backend-hopping" escapes.
**Prevention:** Maintain a unified security specification and audit all VM backends for consistent enforcement of object protection and FFI gating.

## 2026-06-28 - Sandbox Escape via Untagged Reconstructed Modules
**Vulnerability:** In SVM, certain modules (math, sys, gpu) are reconstructed as dictionaries during `OP_IMPORT`. Because these dictionaries lacked the `__type__: "module"` tag, they were not recognized as protected objects by `is_protected`, allowing guests to hijack their functions even in `safe_mode`.
**Learning:** Security tags must be applied to all representations of sensitive objects, including those dynamically reconstructed at runtime, not just to native module wrappers or initial globals.
**Prevention:** Ensure all execution paths that expose sensitive host functionality (like `OP_IMPORT` or `OBJ_GET_GLOBAL`) consistently apply security metadata to the returned objects.

## 2026-06-29 - Sandbox Information Leak via Internal Properties
**Vulnerability:** In both SVM and SRVM, guest code could access internal VM metadata and host bridges stored in dictionaries via properties or keys starting with . For example,  leaked the underlying host bridge object, and  tags could be inspected or manipulated.
**Learning:** Preventing access to sensitive globals is insufficient if those sensitive objects are reachable as properties of allowed objects. Access control must be enforced at the property and index resolution levels.
**Prevention:** Implement a strict blacklist for internal-use keys (e.g.,  prefix) in the VM's property and index access handlers when running in .

## 2026-06-29 - Sandbox Information Leak via Internal Properties
**Vulnerability:** In both SVM and SRVM, guest code could access internal VM metadata and host bridges stored in dictionaries via properties or keys starting with `__`. For example, `math.__host_mod__` leaked the underlying host bridge object, and `__builtin__` tags could be inspected or manipulated.
**Learning:** Preventing access to sensitive globals is insufficient if those sensitive objects are reachable as properties of allowed objects. Access control must be enforced at the property and index resolution levels.
**Prevention:** Implement a strict blacklist for internal-use keys (e.g., `__` prefix) in the VM's property and index access handlers when running in `safe_mode`.

## 2026-06-30 - Command Injection Hardening via Path Validation
**Vulnerability:** The SGVMC compiler used `sys.exec` to invoke the host `sage` compiler, passing user-provided file paths. While some characters were already forbidden, the list was incomplete, leaving risks for shell expansion (globbing) or complex command chaining via characters like `#`, `*`, `?`, or `!`.
**Learning:** When passing input to a shell-based execution function, path validation must be exhaustive. Merely blocking `;` or `&` is insufficient if the shell supports features like globbing or history expansion which can be abused for injection or DoS.
**Prevention:** Implement a central, robust `is_safe_path` helper with a strict blacklist of all shell-sensitive characters and use it consistently for all filesystem paths before they reach a shell-executing function.
