import sys
import io
import svm.sgvm_runner as sgvm_runner
import svm.sgvm_compiler as sgvm_compiler
import svm.sgvm_disassembler_logic as sgvm_disassembler_logic
import svm.sgvm_hexdump_logic as sgvm_hexdump_logic

proc print_help():
    print "Usage: sagevm <command> [options]"
    print ""
    print "Commands:"
    print "  run <file.sgvm> [--debug]         Execute a compiled SGVM binary"
    print "  compile <input.sage> [out.sgvm]   Compile Sage source to SGVM binary"
    print "  dis <file.sgvm> [--sage|--svm]    Disassemble SGVM binary"
    print "  hex <file.sgvm>                   Low-level binary hexdump"
    print "  version                           Show version information"
    print ""
    print "Use 'sagevm <command> --help' for command-specific options."

class SGVMCLI:
    proc init(self):
        # Dispatcher for SGVM tools
        return nil

    proc run(self):
        let args = sys.args()
        var cmd = ""
        if len(args) >= 2:
            cmd = args[1]
        
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
        elif cmd == "version":
            print "SageVM v0.9.7"
        elif cmd == "--help" or cmd == "-h" or cmd == "help":
            print_help()
        else:
            print "Unknown command: " + cmd
            print_help()

    proc handle_run(self, args, start_idx):
        var input_file = ""
        var debug = false
        var safe = false
        var no_ffi = false
        var i = start_idx
        while i < len(args):
            let a = args[i]
            if a == "--debug": debug = true
            elif a == "--safe": safe = true
            elif a == "--no-ffi": no_ffi = true
            else: input_file = a
            i = i + 1
        
        if input_file == "":
            print "Usage: sagevm run <file.sgvm> [--debug] [--safe] [--no-ffi]"
            return
        
        let runner = sgvm_runner.SGVMRunner()
        runner.run_file(input_file, debug, safe, not no_ffi)

    proc handle_compile(self, args, start_idx):
        var input_file = ""
        var output_file = ""
        var use_shebang = false
        var pos_idx = 0
        var i = start_idx
        while i < len(args):
            let a = args[i]
            if a == "--shebang": use_shebang = true
            else:
                if pos_idx == 0: input_file = a
                elif pos_idx == 1: output_file = a
                pos_idx = pos_idx + 1
            i = i + 1
        
        if input_file == "":
            print "Usage: sagevm compile <input.sage> [output.sgvm] [--shebang]"
            return
        
        if output_file == "":
            output_file = input_file + ".sgvm"
        
        let compiler = sgvm_compiler.SGVMCompiler()
        if compiler.compile(input_file, output_file, use_shebang):
            print "✨ Compilation complete: " + output_file
        else:
            print "❌ Compilation failed."

    proc handle_dis(self, args, start_idx):
        var input_file = ""
        var mode = "sage"
        var i = start_idx
        while i < len(args):
            let a = args[i]
            if a == "--svm": mode = "svm"
            elif a == "--sage": mode = "sage"
            else: input_file = a
            i = i + 1
        
        if input_file == "":
            print "Usage: sagevm dis <file.sgvm> [--sage | --svm]"
            return
        
        let dis = sgvm_disassembler_logic.SGVMDisassembler(input_file)
        if dis.disassemble():
            if mode == "svm": print dis.generate_svm()
            else: print dis.generate_sage()

    proc handle_hex(self, args):
        if len(args) < 3:
            print "Usage: sagevm hex <file.sgvm>"
            return
        sgvm_hexdump_logic.disassemble(args[2])
