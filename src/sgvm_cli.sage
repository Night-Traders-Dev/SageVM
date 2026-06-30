gc_disable()
import sys
import io
import sgvm_runner
import sgvm_compiler
import sgvm_disassembler_logic
import sgvm_hexdump_logic
import srvm_runner
import srvm_compiler
import srvm_disassembler_logic
import srvm_hexdump_logic
from sgvm_compiler import sys_exec, io_readfile, io_writebytes

var COLOR_RESET  = ""
var COLOR_BOLD   = ""
var COLOR_RED    = ""
var COLOR_GREEN  = ""
var COLOR_YELLOW = ""
var COLOR_CYAN   = ""

# Check for NO_COLOR or TERM=dumb to disable colors
let env_no_color = sys.getenv("NO_COLOR")
let env_term = sys.getenv("TERM")
if env_no_color == nil and env_term != "dumb":
    COLOR_RESET  = "\x1b[0m"
    COLOR_BOLD   = "\x1b[1m"
    COLOR_RED    = "\x1b[31m"
    COLOR_GREEN  = "\x1b[32m"
    COLOR_YELLOW = "\x1b[33m"
    COLOR_CYAN   = "\x1b[36m"

proc print_help():
    print COLOR_CYAN + COLOR_BOLD + "✨ SageVM v0.9.8" + COLOR_RESET + " - The Sage Virtual Machine"
    print "Usage: " + COLOR_BOLD + "sagevm" + COLOR_RESET + " <command> [options]"
    print ""
    print "Documentation: " + COLOR_CYAN + "https://night-traders-dev.github.io/SageVM-Docs/" + COLOR_RESET
    print ""
    print COLOR_BOLD + "Commands:" + COLOR_RESET
    print "  🚀 " + COLOR_CYAN + "run" + COLOR_RESET + " <file.sgvm|sgrv> Execute a compiled binary"
    print "  🛠️  " + COLOR_CYAN + "compile" + COLOR_RESET + " <file.sage>     Compile Sage source to binary"
    print "  🔍 " + COLOR_CYAN + "dis" + COLOR_RESET + " <file.sgvm|sgrv> Disassemble binary"
    print "  📦 " + COLOR_CYAN + "hex" + COLOR_RESET + " <file.sgvm|sgrv> Low-level binary hexdump"
    print "  ℹ️  " + COLOR_CYAN + "version" + COLOR_RESET + "             Show version information"
    print ""
    print "Flags: -h, --help, -v, --version"

class SGVMCLI:
    proc init(self):
        # Dispatcher for SGVM tools
        return nil

    proc verify_input(self, input_file, is_compile):
        let data = io.readbytes(input_file)
        if data == nil:
            print COLOR_RED + "❌ Error: Could not read file: " + COLOR_RESET + input_file

            # Suggest alternative extensions if they exist
            if not endswith(input_file, ".sgvm") and not endswith(input_file, ".sgrv") and not endswith(input_file, ".sage"):
                if io.readbytes(input_file + ".sgvm") != nil:
                    print COLOR_YELLOW + "💡 Tip: Did you mean " + COLOR_CYAN + input_file + ".sgvm" + COLOR_YELLOW + "?" + COLOR_RESET
                elif io.readbytes(input_file + ".sgrv") != nil:
                    print COLOR_YELLOW + "💡 Tip: Did you mean " + COLOR_CYAN + input_file + ".sgrv" + COLOR_YELLOW + "?" + COLOR_RESET
                elif io.readbytes(input_file + ".sage") != nil:
                    print COLOR_YELLOW + "💡 Tip: " + COLOR_CYAN + input_file + ".sage" + COLOR_YELLOW + " exists. Try compiling it first." + COLOR_RESET
            return nil

        if not is_compile and endswith(input_file, ".sage"):
            print COLOR_YELLOW + "💡 Tip: It looks like you're trying to process a Sage source file with a binary tool." + COLOR_RESET
            print "   Try compiling it first: " + COLOR_CYAN + "sagevm compile " + input_file + COLOR_RESET
        elif is_compile:
            var is_bin = false
            if endswith(input_file, ".sgvm") or endswith(input_file, ".sgrv"):
                is_bin = true
            elif len(data) >= 4:
                let m0 = int(data[0])
                let m1 = int(data[1])
                let m2 = int(data[2])
                let m3 = int(data[3])
                if m0 == 83 and m1 == 71 and m2 == 86 and m3 == 77: is_bin = true # SGVM
                if m0 == 83 and m1 == 71 and m2 == 82 and m3 == 86: is_bin = true # SGRV

            if is_bin:
                print COLOR_YELLOW + "💡 Tip: It looks like you're trying to compile a binary file." + COLOR_RESET
                print "   Try running it instead: " + COLOR_CYAN + "sagevm run " + input_file + COLOR_RESET

        return data

    proc run(self):
        # In compiled binary, sys might be shadowed or nil in some scopes
        # Try to use it directly
        let args = sys.args()
        var cmd = ""
        if len(args) >= 2:
            cmd = args[1]
        
        # Handle standard version and help flags before any dispatch
        if cmd == "-v" or cmd == "--version" or cmd == "version":
            print COLOR_CYAN + COLOR_BOLD + "✨ SageVM v0.9.8" + COLOR_RESET
            return
        if cmd == "-h" or cmd == "--help" or cmd == "help":
            print_help()
            return
        
        # Check if called via symlink
        let binary_name = args[0]
        if endswith(binary_name, "sgvm"):
            self.handle_run(args, 1)
            return
        elif endswith(binary_name, "sgvmc"):
            self.handle_compile(args, 1)
            return

        if cmd == "":
            print_help()
            return

        if cmd == "run":
            self.handle_run(args, 2)
        elif cmd == "compile":
            self.handle_compile(args, 2)
        elif cmd == "dis":
            self.handle_dis(args, 2)
        elif cmd == "hex":
            self.handle_hex(args)
        elif cmd != "":
            print COLOR_RED + "❌ Unknown command: " + COLOR_RESET + cmd

            # Suggest closest match
            let valid_cmds = ["run", "compile", "dis", "hex", "version"]
            var best_match = ""
            var i_cmd = 0
            while i_cmd < len(valid_cmds):
                let v = valid_cmds[i_cmd]
                if startswith(v, cmd) or startswith(cmd, v):
                    best_match = v
                    i_cmd = len(valid_cmds)
                else:
                    i_cmd = i_cmd + 1

            if best_match != "":
                print COLOR_YELLOW + "💡 Tip: Did you mean " + COLOR_CYAN + best_match + COLOR_YELLOW + "?" + COLOR_RESET

            print ""
            print_help()

    proc handle_run(self, args, start_idx):
        var input_file = ""
        var debug = false
        var safe = false
        var no_ffi = false
        var riscv = false
        var i = start_idx
        while i < len(args):
            let a = args[i]
            if a == "--debug": debug = true
            elif a == "--safe": safe = true
            elif a == "--no-ffi": no_ffi = true
            elif a == "--riscv": riscv = true
            elif a == "-v" or a == "--version":
                print COLOR_CYAN + COLOR_BOLD + "✨ SageVM v0.9.8" + COLOR_RESET
                return
            elif a == "-h" or a == "--help":
                print COLOR_CYAN + COLOR_BOLD + "🚀 SageVM Runner" + COLOR_RESET
                print "Usage: " + COLOR_BOLD + "sagevm run" + COLOR_RESET + " <file.sgvm|sgrv> [options]"
                print ""
                print COLOR_BOLD + "Options:" + COLOR_RESET
                print "  --debug    Enable verbose debug logging"
                print "  --safe     Enable safe mode (restricts sensitive modules)"
                print "  --no-ffi   Disable Foreign Function Interface (FFI)"
                print "  --riscv    Force execution using the RISC-V backend"
                return
            else: input_file = a
            i = i + 1
        
        if input_file == "":
            print COLOR_RED + "❌ Error: No input file specified." + COLOR_RESET
            print "Usage: " + COLOR_BOLD + "sagevm run" + COLOR_RESET + " <file.sgvm|sgrv> [--debug] [--safe] [--no-ffi] [--riscv]"
            return
        
        # Verify file existence
        let data = self.verify_input(input_file, false)
        if data == nil: return

        # Auto-detect RISC-V header
        if len(data) >= 4:
            if int(data[0]) == 83 and int(data[1]) == 71 and int(data[2]) == 82 and int(data[3]) == 86:
                riscv = true

        if riscv:
            let runner = srvm_runner.SRVMRunner()
            runner.run_file(input_file, debug, safe, not no_ffi)
        else:
            let runner = sgvm_runner.SGVMRunner()
            runner.run_file(input_file, debug, safe, not no_ffi)

    proc handle_compile(self, args, start_idx):
        var input_file = ""
        var output_file = ""
        var use_shebang = false
        var riscv = false
        var pos_idx = 0
        var iter_idx = start_idx
        while iter_idx < len(args):
            let a = args[iter_idx]
            if a == "--shebang": use_shebang = true
            elif a == "--riscv": riscv = true
            elif a == "-v" or a == "--version":
                print COLOR_CYAN + COLOR_BOLD + "✨ SageVM v0.9.8" + COLOR_RESET
                return
            elif a == "-h" or a == "--help":
                print COLOR_CYAN + COLOR_BOLD + "🛠️  SageVM Compiler" + COLOR_RESET
                print "Usage: " + COLOR_BOLD + "sagevm compile" + COLOR_RESET + " <input.sage> [output.sgvm|sgrv] [options]"
                print ""
                print COLOR_BOLD + "Options:" + COLOR_RESET
                print "  --shebang  Add #!/usr/bin/env sagevm run to output"
                print "  --riscv    Force compilation to RISC-V binary (.sgrv)"
                return
            else:
                if pos_idx == 0: input_file = a
                elif pos_idx == 1: output_file = a
                pos_idx = pos_idx + 1
            iter_idx = iter_idx + 1
        
        if input_file == "":
            print COLOR_RED + "❌ Error: No input file specified." + COLOR_RESET
            print "Usage: " + COLOR_BOLD + "sagevm compile" + COLOR_RESET + " <input.sage> [output.sgvm|sgrv] [--shebang] [--riscv]"
            return
        
        if self.verify_input(input_file, true) == nil: return

        if output_file == "":
            var base = input_file
            if endswith(input_file, ".sage"):
                base = slice(input_file, 0, len(input_file) - 5)
            if riscv: output_file = base + ".sgrv"
            else: output_file = base + ".sgvm"
        
        let compiler = sgvm_compiler.SGVMCompiler()
        if compiler.compile(input_file, output_file, use_shebang):
            if riscv:
                # Post-process: Translate SVM to SRVM
                let svm_data = io.readbytes(output_file)
                let rv_compiler = srvm_compiler.SGRVCompiler()
                let sgrv_data = rv_compiler.compile(svm_data)
                if sgrv_data != nil:
                    io_writebytes(output_file, sgrv_data)
                    print COLOR_GREEN + "✨ RISC-V translation complete." + COLOR_RESET
                else:
                    print COLOR_RED + "❌ RISC-V translation failed." + COLOR_RESET
            let out_data = io.readbytes(output_file)
            var size_str = ""
            if out_data != nil:
                let sz = len(out_data)
                if sz < 1024:
                    size_str = " (" + str(sz) + " bytes)"
                else:
                    # Very simple KB calculation
                    let kb = sz / 1024
                    size_str = " (" + str(kb) + " KB)"

            print COLOR_GREEN + "✨ Compilation complete: " + COLOR_RESET + output_file + size_str
            print "   Run with: " + COLOR_CYAN + "sagevm run " + output_file + COLOR_RESET
        else:
            print COLOR_RED + "❌ Compilation failed." + COLOR_RESET

    proc handle_dis(self, args, start_idx):
        var input_file = ""
        var mode = "sage"
        var riscv = false
        var i = start_idx
        while i < len(args):
            let a = args[i]
            if a == "--svm": mode = "svm"
            elif a == "--sage": mode = "sage"
            elif a == "--riscv": riscv = true
            elif a == "-v" or a == "--version":
                print COLOR_CYAN + COLOR_BOLD + "✨ SageVM v0.9.8" + COLOR_RESET
                return
            elif a == "-h" or a == "--help":
                print COLOR_CYAN + COLOR_BOLD + "🔍 SageVM Disassembler" + COLOR_RESET
                print "Usage: " + COLOR_BOLD + "sagevm dis" + COLOR_RESET + " <file.sgvm|sgrv> [options]"
                print ""
                print COLOR_BOLD + "Options:" + COLOR_RESET
                print "  --sage     Generate readable Sage source code (default)"
                print "  --svm      Generate low-level SVM assembly"
                print "  --riscv    Force disassembly using RISC-V logic"
                return
            else: input_file = a
            i = i + 1
        
        if input_file == "":
            print COLOR_RED + "❌ Error: No input file specified." + COLOR_RESET
            print "Usage: " + COLOR_BOLD + "sagevm dis" + COLOR_RESET + " <file.sgvm> [--sage | --svm] [--riscv]"
            return
        
        # Auto-detect RISC-V header
        let data = self.verify_input(input_file, false)
        if data == nil: return

        if len(data) >= 4:
            if int(data[0]) == 83 and int(data[1]) == 71 and int(data[2]) == 82 and int(data[3]) == 86:
                riscv = true

        if riscv:
            let dis = srvm_disassembler_logic.SRVMDisassembler(input_file)
            if dis.disassemble():
                dis.generate_sage()
        else:
            let dis = sgvm_disassembler_logic.SGVMDisassembler(input_file)
            if dis.disassemble():
                if mode == "svm": print dis.generate_svm()
                else: print dis.generate_sage()

    proc handle_hex(self, args):
        var input_file = ""
        var riscv = false
        var i = 2
        while i < len(args):
            let a = args[i]
            if a == "--riscv": riscv = true
            elif a == "-v" or a == "--version":
                print COLOR_CYAN + COLOR_BOLD + "✨ SageVM v0.9.8" + COLOR_RESET
                return
            elif a == "-h" or a == "--help":
                print COLOR_CYAN + COLOR_BOLD + "📦 SageVM Hexdump Utility" + COLOR_RESET
                print "Usage: " + COLOR_BOLD + "sagevm hex" + COLOR_RESET + " <file.sgvm|sgrv> [options]"
                print ""
                print COLOR_BOLD + "Options:" + COLOR_RESET
                print "  --riscv    Force hexdump using RISC-V logic"
                return
            else: input_file = a
            i = i + 1

        if input_file == "":
            print COLOR_RED + "❌ Error: No input file specified." + COLOR_RESET
            print "Usage: " + COLOR_BOLD + "sagevm hex" + COLOR_RESET + " <file.sgvm|sgrv> [--riscv]"
            return
        
        # Auto-detect RISC-V header
        let data = self.verify_input(input_file, false)
        if data == nil: return

        if len(data) >= 4:
            if int(data[0]) == 83 and int(data[1]) == 71 and int(data[2]) == 82 and int(data[3]) == 86:
                riscv = true

        if riscv:
            srvm_hexdump_logic.srvm_disassemble(input_file)
        else:
            sgvm_hexdump_logic.disassemble(input_file)
