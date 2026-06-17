#!/usr/bin/env python3
"""
Generate the DEFINITIVE 20-Page SageVM Assembly & Architecture Guide.
"""

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, Frame,
    Paragraph, Spacer, PageBreak,
    Table, TableStyle, HRFlowable, Preformatted,
    KeepTogether, NextPageTemplate,
)
from reportlab.lib.colors import HexColor, white, black

# ─── Palette ─────────────────────────────────────────────────────────────────
C_NAVY       = HexColor('#0b1c2c')
C_NAVY_MED   = HexColor('#1a3553')
C_CYAN       = HexColor('#00bcd4')
C_CYAN_DIM   = HexColor('#006e7f')
C_CODE_BG    = HexColor('#0d1117')
C_CODE_FG    = HexColor('#e6edf3')
C_TH_BG      = HexColor('#1a3553')
C_BORDER     = HexColor('#c0cdd8')
C_DIVIDER    = HexColor('#dde6ee')
C_BODY       = HexColor('#1a202c')
C_MUTED      = HexColor('#718096')
C_EXEC_BG    = HexColor('#e8f4fd')
C_EXEC_LEFT  = HexColor('#0078c2')

PAGE_W, PAGE_H = A4
LEFT    = 2.2 * cm
RIGHT   = 1.8 * cm
TOP     = 2.5 * cm
BOTTOM  = 2.5 * cm
CONTENT_W = PAGE_W - LEFT - RIGHT

# ─── Page Drawing ────────────────────────────────────────────────────────────
def draw_content_page(canvas, doc):
    canvas.saveState()
    # DEFINITIVE FIX: Reset background to white on EVERY page
    canvas.setFillColor(white)
    canvas.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    
    # ── Header bar ──
    canvas.setFillColor(C_NAVY)
    canvas.rect(0, PAGE_H - TOP + 0.3 * cm, PAGE_W, TOP - 0.3 * cm, fill=1, stroke=0)
    canvas.setFillColor(C_CYAN)
    canvas.rect(0, PAGE_H - TOP + 0.25 * cm, PAGE_W, 0.05 * cm, fill=1, stroke=0)
    
    canvas.setFont('Courier-Bold', 8)
    canvas.setFillColor(C_CYAN)
    canvas.drawString(LEFT, PAGE_H - TOP + 0.8 * cm, 'SAGEVM: SYSTEMS ASSEMBLY & ARCHITECTURE')
    canvas.setFont('Courier', 7)
    canvas.setFillColor(HexColor('#8bafc4'))
    canvas.drawRightString(PAGE_W - RIGHT, PAGE_H - TOP + 0.8 * cm,
                           'Official Technical Manual  ·  v0.9.8')
    
    # ── Footer ──
    canvas.setFillColor(C_DIVIDER)
    canvas.rect(LEFT, BOTTOM - 0.8 * cm, CONTENT_W, 0.03 * cm, fill=1, stroke=0)
    canvas.setFont('Courier', 8)
    canvas.setFillColor(C_MUTED)
    canvas.drawCentredString(PAGE_W / 2, BOTTOM - 1.2 * cm, f'PAGE {doc.page}')
    canvas.restoreState()

def draw_cover_page(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(C_NAVY)
    canvas.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    canvas.setFillColor(C_CYAN)
    canvas.rect(0, PAGE_H * 0.45, PAGE_W, 0.2 * cm, fill=1, stroke=0)
    canvas.rect(0, PAGE_H - 1.0 * cm, 5.0 * cm, 0.1 * cm, fill=1, stroke=0)
    canvas.setFillColor(C_NAVY_MED)
    canvas.rect(0, 0, PAGE_W, 2.0 * cm, fill=1, stroke=0)
    canvas.setFillColor(C_CYAN)
    canvas.rect(0, 2.0 * cm, PAGE_W, 0.05 * cm, fill=1, stroke=0)
    canvas.setFont('Courier', 8)
    canvas.setFillColor(HexColor('#5d8aa8'))
    canvas.drawString(LEFT, 0.8 * cm, 'Night-Traders-Dev  ·  Core Systems Architecture')
    canvas.drawRightString(PAGE_W - RIGHT, 0.8 * cm, 'Secure Virtual Substrate Project')
    canvas.restoreState()

# ─── Styles ──────────────────────────────────────────────────────────────────
def make_styles():
    return {
        'cover_title': ParagraphStyle('cover_title', fontName='Courier-Bold', fontSize=42, textColor=white, leading=50, alignment=TA_LEFT),
        'cover_sub': ParagraphStyle('cover_sub', fontName='Courier', fontSize=18, textColor=C_CYAN, spaceBefore=10, alignment=TA_LEFT),
        'cover_meta_k': ParagraphStyle('cover_meta_k', fontName='Courier-Bold', fontSize=10, textColor=HexColor('#5d8aa8'), alignment=TA_LEFT),
        'cover_meta_v': ParagraphStyle('cover_meta_v', fontName='Courier', fontSize=10, textColor=white, alignment=TA_LEFT),
        'cover_desc': ParagraphStyle('cover_desc', fontName='Helvetica', fontSize=12, textColor=HexColor('#a8c8e0'), leading=18, alignment=TA_LEFT),
        'h1': ParagraphStyle('h1', fontName='Courier-Bold', fontSize=22, textColor=C_NAVY, spaceBefore=24, spaceAfter=14, leading=26),
        'h2': ParagraphStyle('h2', fontName='Courier-Bold', fontSize=16, textColor=C_NAVY_MED, spaceBefore=20, spaceAfter=10, leading=18),
        'h3': ParagraphStyle('h3', fontName='Courier-Bold', fontSize=12, textColor=black, spaceBefore=14, spaceAfter=8, leading=14),
        'body': ParagraphStyle('body', fontName='Helvetica', fontSize=10.5, textColor=C_BODY, alignment=TA_JUSTIFY, spaceBefore=10, spaceAfter=10, leading=16),
        'bullet': ParagraphStyle('bullet', fontName='Helvetica', fontSize=10.5, textColor=C_BODY, spaceBefore=6, spaceAfter=6, leading=15, leftIndent=24, firstLineIndent=-14),
        'numbered': ParagraphStyle('numbered', fontName='Helvetica', fontSize=10.5, textColor=C_BODY, spaceBefore=6, spaceAfter=6, leading=15, leftIndent=28, firstLineIndent=-18),
        'code': ParagraphStyle('code', fontName='Courier', fontSize=8.5, textColor=C_CODE_FG, leading=12),
        'th': ParagraphStyle('th', fontName='Courier-Bold', fontSize=10, textColor=white, alignment=TA_LEFT),
        'td': ParagraphStyle('td', fontName='Courier', fontSize=9.5, textColor=C_BODY, alignment=TA_LEFT, leading=13),
        'td_mono': ParagraphStyle('td_mono', fontName='Courier', fontSize=9, textColor=C_NAVY_MED, alignment=TA_LEFT, leading=12),
        'exec_body': ParagraphStyle('exec_body', fontName='Helvetica', fontSize=11.5, textColor=HexColor('#0a3d62'), alignment=TA_JUSTIFY, leading=18),
        'end_note': ParagraphStyle('end_note', fontName='Courier', fontSize=9, textColor=C_MUTED, alignment=TA_CENTER),
    }

# ─── Content ──────────────────────────────────────────────────────────────────
CHAPTERS = [
    {
        "title": "1. The Sage Computing Ecosystem",
        "exec": "Sage is not just a language; it is a full-stack vision for secure, portable, and self-hosted computing. The ecosystem bridges the gap between high-level logic and native metal.",
        "theory": [
            "The Sage Computing Ecosystem is a holistic architecture designed to unify high-level application logic with low-level systems programming. At the apex sits SageLang, an indentation-based, strongly-typed language that provides the developer with modern abstractions such as first-class functions, robust object-oriented patterns, and a sophisticated exception handling model. SageLang is designed to be the 'Language of Intent,' where the focus is on problem-solving rather than manual memory management or processor-specific register allocation. However, unlike other high-level languages that rely on external, opaque runtime environments, SageLang is deeply integrated with its execution substrate.",
            "The middle layer of this ecosystem is SageVM, the 'Virtual Infrastructure.' SageVM is unique in that its reference implementation is written entirely in pure SageLang. This layer includes the sgvmc compiler, which translates Sage source code into the SGVM (Sage General Virtual Machine) bytecode format, and the sgvm interpreter. This self-hosting capability is a cornerstone of the Sage philosophy; it ensures that as long as a basic Sage interpreter can be compiled for a new platform, the entire ecosystem—including the compiler, the standard library, and the operating system components—can be bootstrapped from source. This 'meta-circular' design eliminates dependencies on fragile C toolchains and provides a transparent, auditable path from high-level code to executable binary.",
            "At the foundation lies MetalVM, the 'Engine of Execution.' Written in high-performance C, MetalVM serves as the physical heart of the machine. It is responsible for the raw execution of SGVM bytecode, implementing the core fetch-decode-execute loop with extreme efficiency. MetalVM provides the essential services required by the virtual machine, including the garbage collector, the native hardware bridge (for GPU and FFI access), and the Just-In-Time (JIT) compiler. By separating the high-level virtual architecture (SageVM) from the low-level execution engine (MetalVM), the ecosystem achieves a perfect balance: developers write portable, secure bytecode that can be executed at near-native speeds on any hardware where MetalVM is ported."
        ],
        "asm": "; Ecosystem Mapping\n; [High-Level]  let x = 10\n; [Assembly]   CONSTANT 10; DEFINE_GLOBAL \"x\"\n; [Binary]     00 00 01 06 00 05"
    },
    {
        "title": "2. The Theory of Virtual Machines",
        "theory": [
            "The theory of Virtual Machines (VMs) represents one of the most significant advancements in computer science, providing a layer of architectural abstraction that decouples software from the underlying physical hardware. Historically, virtual machines emerged as a solution to the 'Portability Crisis,' where software written for one processor architecture would not run on another without a total rewrite. Early efforts like the p-code machine for Pascal and later the Java Virtual Machine (JVM) pioneered the concept of a Virtual Instruction Set Architecture (V-ISA). A VM effectively emulates a computer system in software, providing a consistent execution environment that remains identical regardless of the underlying host.",
            "Distinguishing between Hardware and Software machines is critical for the systems developer. A Hardware Machine (ISA) is etched into silicon. Its instructions are fixed at the time of fabrication, and adding new functionality requires a new generation of physical chips. A Software Machine (VM), however, is malleable and software-defined. If a new computing paradigm emerges—such as the need for specialized opcodes for neural network processing—the VM specification can be updated, and the execution engine (like MetalVM) can be recompiled to support these new primitives. This flexibility allows SageVM to evolve at the speed of software development rather than the speed of semiconductor manufacturing cycles.",
            "The execution model of a VM centers on the Fetch-Decode-Execute loop. The machine 'fetches' an instruction from memory, 'decodes' the numeric opcode to identify its operation, and then 'executes' the corresponding logic in the host environment. In modern systems, this loop is optimized through 'Threaded Dispatch.' SageVM's dual-architecture approach—supporting both stack and register models—allows it to serve as both an educational reference and a high-performance production runtime, capable of running a secure, capability-based operating system."
        ],
        "asm": "; Concept: The Fetch Loop\nLOOP:\n  FETCH OP\n  DECODE OP\n  DISPATCH OP\n  JUMP LOOP"
    },
    {
        "title": "3. Bytecode and Assembly: The Secret Language",
        "theory": [
            "Bytecode and Assembly Grammar constitute the fundamental language of the Sage Virtual Machine. While SageLang is designed for human readability and high-level logic, Bytecode is optimized for the machine. It is a dense, numeric representation of instructions, where each operation is assigned a specific 'Opcode.' In SageVM, these opcodes are typically single bytes, providing a space of 256 possible operations. This numeric stream is what the VM actually executes. However, because raw hex values are nearly impossible for humans to audit or write without error, the ecosystem provides Assembly Language as a human-readable textual mirror.",
            "The grammar of SageVM assembly maintains a strict 1:1 mapping with the underlying bytecode. When a developer writes ADD in an SVM assembly file, it corresponds exactly to the opcode 0x0F in the resulting binary. This transparency is vital for systems engineering; it allows the programmer to control the exact machine state, manage stack depth, and allocate registers with surgical precision. The assembly language is not just a debugging tool; it is a first-class language within the Sage toolchain. The sgvmc assembler takes this human-readable text and performs 'serialization,' a process that gathers code chunks, builds a centralized Constant Pool for strings and large numbers, and packages everything into the SGVM container format.",
            "Understanding the serialization process is key to writing efficient assembly. Every static value in a program—whether it's the string 'Hello World' or a 64-bit floating-point constant—is stored in the Constant Pool. Instructions then refer to these values via 2-byte indices. This 'String Pooling' mechanism ensures that even if a constant is used hundreds of times throughout a program, it only occupies space once in the binary. Furthermore, the assembler handles the 'flattening' of high-level constructs. A loop in Sage is transformed into a series of conditional jumps and backward loops in assembly. By mastering this grammar, the systems developer gains the ability to understand exactly how the virtual electrons move through the machine."
        ],
        "asm": "; The Mapping Lifecycle\n; Source (Sage) -> print 5 + 10\n; Assembly (SVM) -> CONSTANT 5; CONSTANT 10; ADD; PRINT\n; Bytecode (Hex) -> 00 00 05 00 00 0A 0F 2A"
    },
    {
        "title": "4. Architectural Patterns: Stack vs. Register",
        "theory": [
            "Virtual machine architectures typically converge on one of two dominant patterns: Stack-based (SVM) or Register-based (SRVM). Choosing between these models is a foundational decision that impacts everything from compiler complexity to execution performance. SageVM is unique in its dual-architecture support, implementing both models to satisfy different strategic goals. The Stack-based VM, or SVM, operates on a Last-In, First-Out (LIFO) operand stack. In this model, there are no named registers. All operations implicitly look at the top of the stack for their inputs and push their results back onto the top.",
            "The primary advantage of a stack machine is its extreme instruction density. Because instructions do not need to specify 'addresses' (register indices) for their operands, they can be very small—often just a single byte. This makes stack bytecode ideal for environments where binary size is a critical constraint, such as embedded systems or transmission over limited-bandwidth networks. Furthermore, stack-based code is incredibly easy to generate from a compiler's Abstract Syntax Tree (AST), as the recursive nature of an AST maps naturally to the push/pop mechanics of a stack.",
            "Conversely, a Register-based VM, like Sage's SRVM, operates on a fixed set of virtual registers (typically 32 general-purpose 64-bit bins). Each instruction explicitly names its source and destination registers—for example, add x10, x11, x12. While this increases the size of each instruction, it dramatically reduces the overhead of data movement. Modern physical CPUs are themselves register machines, and a Register V-ISA maps 1:1 to the physical silicon. This makes Register VMs significantly easier to JIT-compile, as the virtual registers can be directly allocated to physical hardware registers. SRVM, by mapping directly to the RISC-V RV64I specification, ensures that Sage code can reach 'Bare-Metal' performance levels."
        ],
        "asm": "; Stack (SVM): PUSH 5, PUSH 10, ADD\n; Register (SRVM): add x1, x2, x3"
    },
    {
        "title": "5. Sage SVM: The Stack Engine",
        "theory": [
            "The Sage SVM (Standard Virtual Machine) is the primary execution substrate for the SageLang compiler and serves as the reference implementation for the entire bytecode ecosystem. It is a sophisticated stack engine designed not just for simple arithmetic, but for the complex needs of a modern, object-oriented language. The core of the SVM is the Operand Stack, an array of dynamically-typed Sage values. Every opcode executed by the machine must adhere to the principle of 'Stack Neutrality.' This means that after an operation or a function call, the stack must be in a predictable state, with no 'leaked' values that could cause an overflow or a crash.",
            "The SVM ecosystem comprises 89 primary opcodes, categorized into functional groups such as Arithmetic, Logic, Control Flow, and OOP. Advanced opcodes like CLASS and METHOD allow the VM to understand object-oriented concepts natively at the bytecode level, rather than emulating them through complex pointer arithmetic. This native support for objects is what allows SageVM to be so efficient despite being an interpreted environment. Additionally, the SVM manages lexical scoping through 'Environment Frames.' When a function is called, the PUSH_ENV opcode creates a new dictionary-based scope for local variables.",
            "Mastering stack management is the first step for any Sage assembly writer. Effective use of the stack involves minimizing unnecessary traffic. For instance, if a value is needed multiple times, the DUP (Duplicate) opcode should be used instead of repeatedly fetching the value from a global or local variable, which would involve expensive dictionary lookups. Traffic management also extends to the constant pool; by grouping constants efficiently, the assembly writer can ensure that the 16-bit indices used by instructions like CONSTANT or GET_GLOBAL are used optimally. The SVM is more than just a toy machine; it is a rigorous, capability-tagged engine."
        ],
        "asm": "; Basic Stack Calculation: (a * b) + (c / d)\nGET_GLOBAL \"a\"\nGET_GLOBAL \"b\"\nMUL              ; [ (a*b) ]\nGET_GLOBAL \"c\"\nGET_GLOBAL \"d\"\nDIV              ; [ (a*b), (c/d) ]\nADD              ; [ (a*b) + (c/d) ]\nPRINT"
    },
    {
        "title": "6. Sage SRVM: The Register Engine",
        "theory": [
            "SRVM represents the high-performance tier of the Sage execution model. By adopting a register-based architecture, SRVM breaks free from the 'Stack Traffic' bottleneck that often limits interpreted languages. The machine provides 32 general-purpose registers, labeled x0 through x31. This design choice is not arbitrary; it is an explicit mapping to the RISC-V 64-bit Integer (RV64I) specification. This alignment allows Sage to leverage decades of research into RISC optimization and provides a direct path to native execution on physical RISC-V hardware.",
            "In SRVM, registers are treated as the primary storage for working data. The x0 register is hardwired to zero, a common RISC pattern that simplifies many logic operations. Registers x10 through x17 are designated as argument and return value registers (a0-a7), following the standard RISC-V calling convention. This ABI compatibility is what enables the 'Native Bridge' to work so seamlessly; when Sage code calls a C function, the registers are already in the state the C function expects. This eliminates the need for expensive 'shuffling' or wrapping of arguments that plagues other virtual machines.",
            "Beyond generic computation, SRVM includes the custom VMSYS extension. Because standard RISC-V has no concept of 'Sage Objects' or 'Global Scopes,' the VMSYS instruction (implemented as a repurposed SYSTEM opcode) provides a high-level interface to the VM's core services. This includes object allocation, dictionary manipulation, and environment pushing. This hybrid approach—combining a rigorous industry-standard ISA with high-level VM extensions—makes SRVM the ideal target for performance-critical systems components, such as kernels, drivers, and high-frequency trading algorithms."
        ],
        "asm": "; SRVM: Creating and Printing a Dictionary\nldc   x10, 0x00   ; Constant index for empty key map\nvmsys x10, 0x08   ; VMO_DICT_NEW -> Result in a0\nldc   x11, 0x01   ; Constant index for \"status\"\nldc   x12, 0x02   ; Constant index for \"ready\"\nvmsys x10, 0x0A   ; OBJ_SET_INDEX(dict=a0, key=a1, val=a2)\nvmsys x10, 0x09   ; VMO_PRINT(a0)\nvmsys x0, 0x01    ; VMO_HALT"
    },
    {
        "title": "7. The Compilation Pipeline",
        "theory": [
            "The journey of a Sage program from human-readable text to executable virtual machine instructions is a multi-stage transformation process. This pipeline is designed for modularity, allowing each phase to be independently audited and optimized. The process begins with the Source Stage, where .sage files are processed by the frontend lexer and parser. This frontend is responsible for ensuring the syntactic correctness of the code and building the Abstract Syntax Tree (AST), a hierarchical representation of the program's logic.",
            "Once the AST is established, the compiler enters the Instruction Selection phase. Here, the logical nodes of the tree are mapped to the target V-ISA. Depending on the developer's needs, the emitter can produce SVM (stack-based) or SRVM (register-based) assembly. This 'Intermediate' stage produces .svm or .rv files—textual representations of the bytecode. These files are human-readable, allowing systems developers to inspect the compiler's output and verify that the high-level intent has been correctly translated into low-level operations.",
            "The final phase is Linking and Serialization, handled by the sgvmc tool. The linker gathers modular code chunks, resolves function references, and constructs the centralized Constant Pool. Serialization then packages these components into the SGVM binary format, performing the final big-endian encoding of all numeric values. The resulting .sgvm file is a dense, portable artifact ready for execution. By understanding this pipeline, the developer gains the ability to debug 'at the boundary'—identifying whether a bug exists in the high-level logic, the AST generation, or the final binary serialization."
        ],
        "asm": "; Pipeline Trace: x = 1 + 2\n; 1. AST: Assign(Name(\"x\"), Add(Num(1), Num(2)))\n; 2. Asm: CONSTANT 1; CONSTANT 2; ADD; DEFINE_GLOBAL \"x\"\n; 3. Bin: 00 00 01 00 00 02 0F 06 00 03"
    },
    {
        "title": "8. Binary Internals: The SGVM Format",
        "theory": [
            "The SGVM (.sgvm) format is the standardized binary container for the Sage Virtual Machine. It is designed with three primary goals: parsing efficiency, architectural neutrality, and compactness. Unlike simple text-based formats, SGVM uses a structured binary layout that allows the VM to 'jump' directly to specific code chunks or constant entries without scanning the entire file. This makes loading large programs instantaneous, even on resource-constrained hardware.",
            "The file begins with a 4-byte Magic Number ('SGVM'), followed by versioning information that ensures the binary is compatible with the host runtime. The header also includes critical counts for the number of functions and constant pool entries. Following the header is the Constant Pool, the 'Data Heart' of the binary. Every string, floating-point number, and large integer used by the program is stored here. By referencing these via 2-byte indices, the SGVM format achieves significant deduplication. If the string 'error' appears fifty times in a script, it only occupies space once in the pool.",
            "The final section of the binary is the Chunk Table. In SageVM, code is organized into modular 'Chunks' representing functions or top-level script bodies. Each entry in the table specifies the length of the bytecode and the raw byte stream itself. This modularity is what enables the VM's sophisticated 'Chunk Loading' system, where functions are only loaded into active memory when they are first called. This minimizes the initial memory footprint and provides a natural boundary for the VM's capability-based security model, where permissions can be applied per-chunk."
        ],
        "asm": "; SGVM Header Specification\n; Offset 0x00: 53 47 56 4D (SGVM)\n; Offset 0x04: 01 00 (Ver 1.0)\n; Offset 0x06: [uint16] Function Count\n; Offset 0x08: [uint16] Constant Pool Count\n; [Constant Data Entries...]\n; [Chunk Data Table...]"
    },
    {
        "title": "9. SGVM vs. ELF: A Technical Comparison",
        "theory": [
            "In the world of Linux and Unix-like operating systems, the Executable and Linkable Format (ELF) is the undisputed standard for binary containers. ELF was designed in the late 1980s to hold native machine code, symbol tables, and relocation information for physical CPUs. However, for a modern, high-level virtual machine ecosystem like Sage, ELF carries significant 'Hardware Debt.' ELF assumes that the loader is the OS kernel and that the code inside consists of raw instructions for a specific piece of silicon.",
            "SageVM uses the SGVM format instead of ELF primarily for Architectural Neutrality. An ELF file compiled for an x86 processor is fundamentally useless on an ARM or RISC-V chip. An SGVM file, however, contains bytecode; it is 'CPU Blind.' This allows a Sage developer to compile a program once and distribute it to any hardware platform where a SageVM exists. Furthermore, SGVM binaries are tagged with Capability Metadata at the binary level. This enables instruction-level sandboxing, where a binary can be restricted from network access or filesystem writes by the VM itself—a level of security that is impossible to achieve with the 'all-or-nothing' execution model of ELF.",
            "Another critical differentiator is Runtime Integration. Because SGVM is built specifically for the Sage ecosystem, it carries the metadata required for the VM to integrate the code directly with the runtime Garbage Collector and Object System. ELF files have no concept of 'Classes' or 'Managed Objects,' forcing other languages (like Java or Python) to build complex 'Wrapper' formats. By using SGVM, SageVM eliminates this overhead, providing a clean, direct path from the binary file into the heart of the virtual machine's object graph."
        ],
        "asm": "; Capability Comparison\n; SGVM binary -> [CAP_NET=0, CAP_GPU=1]\n; Opcode IMPORT \"net\" -> VM PANIC (Permission Denied)\n; Opcode GPU_DRAW -> SUCCESS"
    },
    {
        "title": "10. Systems Engineering: Bootloaders & Kernels",
        "theory": [
            "In the Sage Computing Ecosystem, systems engineering is not a secondary concern; it is the primary focus. While other virtual machines are designed to run 'Apps' on top of an existing OS, SageVM is designed to be the substrate for the OS itself. In this context, the SRVM (Register-based VM) acts as the 'Virtual Silicon.' Writing a kernel for SageOS begins with understanding how the machine starts from a 'Cold State.' The first code to execute is the Bootloader, which is responsible for initializing the register file and setting up the global environment.",
            "The SRVM Bootloader pattern is a masterclass in low-level control. The machine starts with all registers (except x0) in an uninitialized state. The bootloader must manually load the address of the memory heap into the global pointer (gp) and set up the initial stack pointer (sp). It then uses the custom VMSYS instruction to 'Push' the primary environment, creating the isolation boundary between the 'System' space and the 'Kernel' space. Finally, it uses the VMO_CALL service to transfer control to the kernel's entry point. If the kernel ever returns, the bootloader triggers a VM_HALT, effectively 'shutting down' the virtual computer.",
            "This architectural model provides a 'Zero-Trust' systems environment. Because every instruction is monitored by the VM, a kernel written in SRVM assembly cannot 'accidentally' overwrite the VM's own internal state or access hardware it hasn't been granted permission for. This is the foundation of SageOS security: the OS is as secure as the VM's opcode implementations. By using assembly for these foundational layers, developers can squeeze the maximum possible performance out of the boot process while maintaining the absolute safety and auditability of the Sage environment."
        ],
        "asm": "; --- SRVM Kernel Bootloader ---\nldc   x10, 0x00   ; Index 0: Memory Heap Arena\nmv    x3, x10     ; x3 (gp) = Heap Pointer\nldc   x10, 0x01   ; Index 1: Stack Space (Initial)\nmv    x2, x10     ; x2 (sp) = Stack Pointer\nvmsys x0, 0x02    ; Initialize Kernel Scope (PUSH_ENV)\nldc   x10, 0x02   ; Index 2: kernel_main function pointer\nvmsys x10, 0x04   ; Transfer Control (VMO_CALL)\nvmsys x0, 0x01    ; VM_HALT if kernel returns"
    },
    {
        "title": "11. Advanced Graphics: The Vulkan Bridge",
        "theory": [
            "SageVM treats high-performance graphics as a first-class citizen, not an afterthought. To achieve this, the VM specification includes 28 dedicated GPU opcodes (59-86). These opcodes provide a direct, low-latency bridge to the host system's hardware-accelerated graphics implementation, typically using Vulkan or OpenGL. Unlike traditional virtual machines that rely on slow, high-level API wrappers, SageVM allows assembly writers to build graphics command buffers directly at the instruction level.",
            "The graphics model in SageVM is Asynchronous and Command-Driven. The CPU does not 'draw' to the screen; instead, it records a stream of commands into a buffer. These commands include viewport settings, graphics pipeline bindings, vertex buffer descriptors, and draw calls. Once the buffer is complete, it is 'submitted' to the GPU backend. This approach maximizes the system's overall throughput by allowing the virtual CPU to continue processing program logic while the physical GPU renders the previous frame in parallel.",
            "Synchronization is the final piece of the graphics puzzle. Because the GPU operates independently, the assembly writer must use Fences and Semaphores to ensure that data is ready before it is presented to the screen. The OP_GPU_WAIT_FENCE instruction allows the assembly to pause until the GPU has finished a specific render pass. This tight integration of graphics opcodes into the core ISA makes SageVM the primary choice for building real-time simulations, 3D game engines, and visually rich operating system interfaces within a pure-virtual environment."
        ],
        "asm": "; Build GPU Render Pass in Assembly\nOP_GPU_POLL_EVENTS\nCONSTANT 0; OP_GPU_ACQUIRE_IMG\nDEFINE_GLOBAL \"framebuffer\"\nCONSTANT 1; OP_GPU_BEGIN_COMMANDS\nGET_GLOBAL \"framebuffer\"\nCONSTANT 2; OP_GPU_CMD_BEGIN_RP   ; Begin Render Pass\nCONSTANT 3; OP_GPU_CMD_BIND_GP    ; Bind Graphics Pipeline\nOP_GPU_CMD_DRAW                   ; vertex_count=3\nOP_GPU_CMD_END_RP\nOP_GPU_END_COMMANDS\nOP_GPU_PRESENT                    ; Present to Screen"
    },
    {
        "title": "12. Object-Oriented Assembly Mechanics",
        "theory": [
            "Unlike simple virtual machines that treat everything as raw numbers or memory addresses, SageVM understands classes, methods, and inheritance at the opcode level. This architectural 'Awareness of Objects' is what enables the sophisticated dispatch system of SageLang. In assembly, a class is not just a blob of memory; it is a structured entity with a Method Table and a Property Map. When the compiler encounters a method call, it doesn't just jump to an address; it emits a CALL_METHOD opcode.",
            "The Method Table is a dictionary mapping method names (resolved via the Constant Pool) to code chunks. When the VM executes CALL_METHOD, it performs an optimized lookup in the instance's class table. This dispatch logic is implemented in high-performance C within MetalVM, ensuring that the overhead of object-oriented programming is negligible. Furthermore, SageVM handles inheritance through the INHERIT opcode, which performs a shallow copy of a parent class's method table into a new derived class, providing a clean and efficient path for polymorphic behavior.",
            "The final piece of the OO puzzle is 'self' injection. When an instance method is called, the VM automatically manages the argument stack to ensure the object instance is passed as the first argument (__arg0). This behavior is baked into the VM's calling convention, eliminating the need for the assembly writer to manually manage pointer arithmetic or 'this' context. By providing these high-level primitives, SageVM allows developers to build complex, manageable software systems that are as flexible as high-level scripts but as powerful as low-level machine code."
        ],
        "asm": "; OO Implementation: Definition and Call\nCLASS \"Point\"\nMETHOD \"init\"            ; Bind constructor chunk\nMETHOD \"move\"            ; Bind logic chunk\nCONSTANT 10\nCONSTANT 20\nCALL 2                   ; Point.init(instance, 10, 20)\nDEFINE_GLOBAL \"p\"\nGET_GLOBAL \"p\"\nCONSTANT 5\nCALL_METHOD \"move\", 1    ; p.move(5)"
    },
    {
        "title": "13. Exception Handling and Safety",
        "theory": [
            "SageVM ensures the stability of the entire computing ecosystem through a robust, low-overhead exception handling mechanism. This system is designed to provide 'Runtime Safety' even in the most critical systems-level assembly code. The mechanism is based on two specialized opcodes: SETUP_TRY and RAISE. These instructions interact with a hidden, per-thread Handler Stack that tracks the recovery points established by the program's logic.",
            "When a SETUP_TRY instruction is executed, the VM pushes a 'Recovery Record' onto the handler stack. This record stores the current operand stack depth, the instruction pointer of the 'catch' block, and the state of the environment scopes. If a RAISE instruction occurs—whether triggered by a manual error or a VM panic (such as a Zero Division)—the machine initiates the 'Unwinding' process. It searches the handler stack for the nearest recovery point and 'pops' all data from the operand stack until it reaches the state saved in the record. It then jumps directly to the catch block, placing the exception object at the top of the stack.",
            "This unwinding guarantee is what makes SageVM assembly so resilient. Even if a low-level routine crashes deep within a recursive algorithm, the VM can safely restore the machine to a stable state without leaking memory or corrupting the global environment. This is a level of safety that raw C-based kernels lack, where a single unhandled null pointer can bring down the entire system. In SageVM, the exception handler is the ultimate safeguard, ensuring that errors are contained and managed according to the developer's intent."
        ],
        "asm": "; SVM Exception Pattern\nSETUP_TRY ERROR_HANDLER\nGET_GLOBAL \"divisor\"\nCONSTANT 0; EQUAL\nJUMP_IF_FALSE PROCEED\nCONSTANT \"Division by Zero\"\nRAISE\nPROCEED:\n; ... logic ...\nEND_TRY\nJUMP EXIT\nERROR_HANDLER:\n  PRINT   ; Output the error object\nEXIT:\n  HALT"
    },
    {
        "title": "14. Optimization for Assembly Writers",
        "theory": [
            "In a virtual environment, every opcode has a cost. While MetalVM is highly optimized, the systems developer must still employ clever strategies to squeeze the maximum possible performance out of the machine. Efficiency in SageVM is measured in two primary metrics: Instruction Count and Dictionary Traffic. Because global variables and method lookups involve hash-map searches, the assembly writer should always strive to keep 'Hot Data' on the stack or in registers.",
            "A key technique for SVM optimization is Traffic Reduction using the DUP opcode. If a value is needed for multiple calculations, it is significantly faster to load it once and use DUP to replicate the value on the stack, rather than calling GET_GLOBAL multiple times. For SRVM (the register machine), the focus shifts to Register Pressure. Developers should utilize the 'Saved' registers (x18-x27) for data that must persist across function calls, effectively reducing the need for costly 'Stack Spills' where data is moved from fast registers into slow memory.",
            "Finally, Loop Unrolling is a powerful tool for reducing the overhead of branching logic. Interpreter overhead is primarily located in the fetch-decode cycle and the branch prediction at the end of each opcode. By performing four operations in a single loop iteration instead of one, and adjusting the iteration count accordingly, the developer can reduce the number of JUMP or LOOP_BACK operations by 75%. While this increases the binary size slightly, the performance gain in the 'Hot Path' is often substantial. By mastering these micro-optimizations, the assembly writer ensures that Sage code runs with the precision and speed of native silicon."
        ],
        "asm": "; Optimization: Using DUP vs GET_GLOBAL\n; [Slow]\nGET_GLOBAL \"x\"; CONSTANT 1; ADD\nGET_GLOBAL \"x\"; CONSTANT 2; MUL\n; [Fast]\nGET_GLOBAL \"x\"\nDUP; CONSTANT 1; ADD; PRINT\nCONSTANT 2; MUL; PRINT"
    },
    {
        "title": "15. The Roadmap: Path to v1.0 and Beyond",
        "theory": [
            "SageVM is a living, breathing architecture, and the journey to version 1.0 is focused on closing the gap between virtual abstraction and physical native performance. The roadmap is defined by two primary engineering thrusts: Background JIT Acceleration and Native Hardware Integration. These advancements will transform Sage from a sophisticated virtual environment into a first-class systems implementation language capable of competing with C and Rust on raw performance.",
            "The next major release of MetalVM will introduce the Background JIT Engine. This thread-safe compiler will monitor 'Hot' chunks of assembly in real-time. Once a chunk exceeds an execution threshold (e.g., 1,000 calls), the JIT will translate the bytecode into native machine code (x86_64, ARM64, or RISC-V) in the background. Once ready, the VM will 'Hot-Swap' the interpreted chunk with the native binary. This 'Tiered Compilation' approach will provide a 10x to 50x performance boost for algorithmic tasks while maintaining the portability of the SGVM binary format.",
            "Looking further ahead, we are exploring RISC-V Bare-Metal Backends. Because the SRVM architecture is already a strict mapping of the RISC-V ISA, it is possible to run Sage binaries directly on physical RISC-V silicon with zero software translation. We are developing a specialized 'Micro-MetalVM'—a tiny, C-based runtime that acts as the minimal hardware abstraction layer (HAL) for physical chips. This will allow Sage to be used as the primary language for secure, high-performance firmware and embedded systems, realizing the vision of a truly 'Universal Substrate' for computing."
        ],
        "asm": "; Future Path: [Bytecode] -> [JIT Tier 1] -> [Native Tier 2]\n; Current Status: v0.9.8 LTS\n; Targeted Release v1.0: June 2027"
    }
]

# ─── Helper Builders ─────────────────────────────────────────────────────────
def h1(text, S): return [Spacer(1, 15), Paragraph(text, S['h1']), HRFlowable(width='100%', thickness=2.5, color=C_CYAN, spaceAfter=10, spaceBefore=4)]
def h2(text, S): return [Paragraph(text, S['h2'])]
def h3(text, S): return [Paragraph(text, S['h3'])]
def p(text, S): return [Paragraph(text, S['body'])]
def bullet(items, S): return [Paragraph(f'\u2022\u2002{item}', S['bullet']) for item in items]
def numbered(items, S): return [Paragraph(f'<b>{i}.</b>\u2003{item}', S['numbered']) for i, item in enumerate(items, 1)]
def code_block(text, S):
    pre = Preformatted(text.strip('\n'), S['code'])
    tbl = Table([[pre]], colWidths=[CONTENT_W])
    tbl.setStyle(TableStyle([('BACKGROUND', (0, 0), (-1, -1), C_CODE_BG), ('LEFTPADDING', (0, 0), (-1, -1), 15), ('RIGHTPADDING', (0, 0), (-1, -1), 15), ('TOPPADDING', (0, 0), (-1, -1), 12), ('BOTTOMPADDING', (0, 0), (-1, -1), 12), ('BOX', (0, 0), (-1, -1), 0.8, HexColor('#30363d')), ('LINEABOVE', (0, 0), (-1, 0), 4, C_CYAN_DIM)]))
    return [Spacer(1, 8), tbl, Spacer(1, 8)]
def exec_box(text, S):
    tbl = Table([[Paragraph(text, S['exec_body'])]], colWidths=[CONTENT_W])
    tbl.setStyle(TableStyle([('BACKGROUND', (0, 0), (-1, -1), C_EXEC_BG), ('LEFTPADDING', (0, 0), (-1, -1), 20), ('RIGHTPADDING', (0, 0), (-1, -1), 20), ('TOPPADDING', (0, 0), (-1, -1), 18), ('BOTTOMPADDING', (0, 0), (-1, -1), 18), ('LINEBEFORE', (0, 0), (0, -1), 6, C_EXEC_LEFT), ('BOX', (0, 0), (-1, -1), 0.5, C_BORDER)]))
    return [Spacer(1, 10), tbl, Spacer(1, 12)]
def data_table(headers, rows, col_widths, S, mono_cols=None):
    mono_cols = mono_cols or []
    data = [[Paragraph(h, S['th']) for h in headers]]
    for row in rows:
        data.append([Paragraph(str(c), S['td_mono'] if i in mono_cols else S['td']) for i, c in enumerate(row)])
    tbl = Table(data, colWidths=col_widths)
    tbl.setStyle(TableStyle([('BACKGROUND', (0, 0), (-1, 0), C_TH_BG), ('GRID', (0, 0), (-1, -1), 0.5, C_BORDER), ('LEFTPADDING', (0, 0), (-1, -1), 10), ('RIGHTPADDING', (0, 0), (-1, -1), 10), ('VALIGN', (0, 0), (-1, -1), 'TOP'), ('LINEBELOW', (0, 0), (-1, 0), 2.5, C_CYAN_DIM)]))
    return [Spacer(1, 10), tbl, Spacer(1, 12)]
def hr(): return [Spacer(1, 12), HRFlowable(width='100%', thickness=0.5, color=C_DIVIDER), Spacer(1, 12)]

# ─── Main Build ───────────────────────────────────────────────────────────────
def build():
    OUTPUT = 'docs/SageVM_Assembly_Guide.pdf'
    doc = BaseDocTemplate(OUTPUT, pagesize=A4, leftMargin=LEFT, rightMargin=RIGHT, topMargin=TOP, bottomMargin=BOTTOM)
    content_frame = Frame(LEFT, BOTTOM, CONTENT_W, PAGE_H - TOP - BOTTOM, id='body')
    doc.addPageTemplates([
        PageTemplate(id='Cover', frames=[content_frame], onPage=draw_cover_page),
        PageTemplate(id='Content', frames=[content_frame], onPage=draw_content_page)
    ])
    S = make_styles()
    story = []

    # COVER
    story.append(NextPageTemplate('Cover'))
    story += [Spacer(1, PAGE_H * 0.15), Paragraph('SAGEVM', S['cover_title']), Paragraph('Definitive Systems Assembly Guide', S['cover_sub']), Spacer(1, 0.5 * cm), HRFlowable(width='100%', thickness=1.2, color=C_CYAN, spaceAfter=20)]
    meta = [('Version', '0.9.8 (LTS)'), ('Organization', 'Night-Traders-Dev'), ('Targets', 'SVM-Stack / SRVM-RV64'), ('Security', 'Capability-Based Virtualization'), ('Status', 'Official Systems Engineering Manual')]
    meta_tbl = Table([[Paragraph(k, S['cover_meta_k']), Paragraph(v, S['cover_meta_v'])] for k, v in meta], colWidths=[4.8 * cm, CONTENT_W - 4.8 * cm])
    meta_tbl.setStyle(TableStyle([('LEFTPADDING', (0, 0), (-1, -1), 0), ('TOPPADDING', (0, 0), (-1, -1), 6), ('LINEBELOW', (0, 0), (-1, -2), 0.5, HexColor('#1e3a54'))]))
    story += [meta_tbl, Spacer(1, 2.5 * cm), Paragraph('The definitive technical manual for low-level development within the Sage ecosystem. This volume provides an exhaustive exploration of software machine theory, the dual-architecture substrate, binary internals, and advanced systems engineering patterns.', S['cover_desc']), PageBreak()]

    # CONTENT
    story.append(NextPageTemplate('Content'))
    
    for ch in CHAPTERS:
        story += h1(ch["title"], S)
        if "exec" in ch:
            story += exec_box(ch["exec"], S)
        
        for p_text in ch["theory"]:
            story += p(p_text, S)
        
        if "asm" in ch:
            story += h3("Code Presentation / Pattern", S)
            story += code_block(ch["asm"], S)
        
        # Add extra spacing between chapters or a page break for large ones
        story.append(PageBreak())

    # FINAL
    story += [
        Spacer(1, 30),
        HRFlowable(width='100%', thickness=0.5, color=C_DIVIDER),
        Spacer(1, 10),
        Paragraph('End of Document  ·  Definitive SageVM Assembly Guide v0.9.8', S['end_note']),
        Paragraph('A Technical Publication of Night-Traders-Dev Core Systems Group', S['end_note']),
    ]

    doc.build(story)
    print(f'✓  Massive Technical Guide PDF written to {OUTPUT}')

if __name__ == '__main__':
    build()
