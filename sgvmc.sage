import sys
import io
from sgvm_compiler import SGVMCompiler

proc main():
    let args = sys.args()
    var input_file = ""
    var output_file = ""
    var use_shebang = false
    var i = 0
    while i < len(args):
        let a = args[i]
        if endswith(a, ".sage"):
            input_file = a
        elif endswith(a, ".sgvm"):
            output_file = a
        elif a == "--shebang":
            use_shebang = true
        i = i + 1
    if input_file == "" or output_file == "":
        print "Usage: sgvmc <input.sage> <output.sgvm> [--shebang]"
        return
    
    let compiler = SGVMCompiler()
    compiler.compile(input_file, output_file, use_shebang)
    print "Compilation complete."

main()
