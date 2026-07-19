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
**Vulnerability:** In both SVM and SRVM, guest code could access internal VM metadata and host bridges stored in dictionaries via properties or keys starting with `__`. For example, `math.__host_mod__` leaked the underlying host bridge object, and `__builtin__` tags could be inspected or manipulated.
**Learning:** Preventing access to sensitive globals is insufficient if those sensitive objects are reachable as properties of allowed objects. Access control must be enforced at the property and index resolution levels.
**Prevention:** Implement a strict blacklist for internal-use keys (e.g., `__` prefix) in the VM's property and index access handlers when running in `safe_mode`.

## 2026-07-02 - Hardening SGVMC Compiler against Command Injection
**Vulnerability:** The SGVM compiler used a weak blacklist for path validation and lacked argument quoting when invoking the SageLang host via a shell command. Maliciously crafted paths could bypass the blacklist and execute arbitrary commands on the host.
**Learning:** Blacklists are fragile and often insufficient for shell-based command construction. Even "safe" characters like spaces can be problematic if not handled correctly with quoting. Whitelisting is the only robust approach.
**Prevention:** Use a strict whitelist for all inputs that end up in a shell command, explicitly block leading hyphens to prevent flag injection, and always use single-quoting for arguments to provide defense-in-depth.

## 2026-07-07 - Out-of-Bounds Access in VM Constant Pool and Chunks
**Vulnerability:** The SVM and SRVM interpreters lacked bounds checking when indexing into the constant pool and code chunks using guest-provided indices. A malicious binary could provide indices outside the valid range, leading to 'nil' values being propagated into VM operations, causing unpredictable behavior or host-level runtime errors.
**Learning:** Virtual machine implementations must strictly validate all indices decoded from guest bytecode before using them to access internal VM structures. Failure to do so can break the sandbox's integrity and lead to denial-of-service or information leakage.
**Prevention:** Always implement explicit bounds checks at the point of access for all VM-internal collections (constants, chunks, stacks) and provide clean VM-level error reporting instead of letting errors propagate to the host.

## 2026-07-16 - Sandbox Escape/Bypass via Unrestricted Struct Module in SVM
**Vulnerability:** The SVM sandbox restricts access to sensitive standard modules (e.g., io, mem, ffi) in `safe_mode` by removing them from `globals` and blacklisting them during `OP_IMPORT`. However, the `struct` module was unconditionally exposed in globals and was missing from the import blacklist, allowing guest code to resolve it and bypass sandbox restrictions.
**Learning:** Whitelisting modules in safe mode is much safer than blacklisting; when using hybrid approaches, all sensitive builtins and modules must be consistently isolated. A single missing check in either initialization or import logic breaks the guest-isolation boundaries.
**Prevention:** Always maintain a centralized, single source of truth for the list of restricted/sensitive modules, and verify that all VM backends enforce restrictions on this list during both environment initialization and module import resolution.

## 2026-07-17 - Hot-Loop Bounds Checks Bypass (Out-of-Bounds Access) in SVM
**Vulnerability:** Inlined VM performance optimizations in `MetalVM.run` bypassed the bounds checking previously implemented in `safe_get_constant` and fallback helper `execute_op`. Specifically, optimized opcodes `OP_GET_LOCAL`, `OP_SET_LOCAL`, `OP_DUP`, `OP_GET_PROPERTY`, and `OP_SET_PROPERTY` indexed directly into host arrays/lists without validation, allowing a malformed guest bytecode to trigger host-level runtime errors.
**Learning:** Inlining operations into interpreter dispatch hot-loops often compromises architectural boundary checks if they are only implemented in cold-path helpers. Any optimization must replicate the security/bounds contracts of the slow path.
**Prevention:** Always mirror security limits and index/size bounds checks into all inlined or fast-path representations of instructions.

## 2026-07-19 - Sandbox Escape & Info Leak via Unhardened High-Level Builtins (SVM/SRVM)
**Vulnerability:** High-level list and dictionary builtins (e.g., `push`, `pop`, `dict_has`, `dict_keys`, `dict_values`) bypassed normal property/index-level sandbox access controls (`OP_SET_PROPERTY`, `OP_SET_INDEX`) in `safe_mode`. Guest code could directly invoke `push` or `pop` on protected objects (like `math` module wrappers) to mutate them, and could call `dict_keys` to inspect internal/sensitive metadata properties (starting with `__`).
**Learning:** Hardening property and index access opcodes is insufficient if guest code can manipulate those same objects using standard library builtins. Security checks and filters must be consistently applied within all builtin handlers that operate on containers.
**Prevention:** Always check `is_protected` inside container-mutating builtins (like `push`/`pop`) and strip out internal/private keys (e.g., `__`-prefixed properties) from reflection-like builtins (such as `dict_keys` or `dict_values`) when running under sandboxed execution modes.
