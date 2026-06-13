#!/usr/bin/env python3
"""
patch_sagevm.py
Patches SageVM to add math.printm() support.
Run from the root of the SageVM repository.

Architecture:
- src/sgvm_core.sage  : Opcode definitions (OP_PRINT=42, OP_HALT=255)
- src/sgvm_vm.sage    : VM interpreter with delegation bridge
- src/sgvm_compiler.sage : Bytecode compiler
- sgvm.sage / sgvmc.sage : Entrypoint wrappers

Since math is delegated to host via self.globals["math"] = math,
math.printm() primarily needs to exist in the host SageLang math module.
But we also add OP_MATH_PRINTM for standalone VM execution.
"""

import os
import sys

def read_file(path):
    with open(path, "r") as f:
        return f.read()

def write_file(path, content):
    with open(path, "w") as f:
        f.write(content)

def backup_file(path):
    backup = path + ".backup"
    if not os.path.exists(backup):
        with open(backup, "w") as f:
            f.write(read_file(path))
        print(f"[BACKUP] {backup}")

def patch_sgvm_core():
    """Patch src/sgvm_core.sage — add OP_MATH_PRINTM opcode."""
    target = "src/sgvm_core.sage"
    content = read_file(target)

    if "OP_MATH_PRINTM" in content:
        print(f"[OK] {target} already has OP_MATH_PRINTM")
        return False

    # Insert before OP_HALT = 255
    content = content.replace(
        "let OP_HALT           = 255",
        "let OP_MATH_PRINTM    = 87\nlet OP_HALT           = 255"
    )

    backup_file(target)
    write_file(target, content)
    print(f"[PATCHED] {target} — added OP_MATH_PRINTM = 87")
    return True

def patch_sgvm_vm():
    """Patch src/sgvm_vm.sage — handle OP_MATH_PRINTM in VM dispatch."""
    target = "src/sgvm_vm.sage"
    content = read_file(target)

    if "OP_MATH_PRINTM" in content:
        print(f"[OK] {target} already handles OP_MATH_PRINTM")
        return False

    # 1. Add OP_MATH_PRINTM to the import list
    content = content.replace(
        "OP_PRINT, OP_EXEC_AST_STMT, OP_RETURN",
        "OP_PRINT, OP_EXEC_AST_STMT, OP_RETURN, OP_MATH_PRINTM"
    )

    # 2. Add the opcode handler in the run_step() dispatch
    marker = """        elif op == OP_PRINT:
            print pop(self.stack)"""

    if marker in content:
        handler = """
        elif op == OP_MATH_PRINTM:
            let matrix = pop(self.stack)
            if type(matrix) != "array":
                print "Error: math.printm() expects an array"
                self.halted = true
                return false
            end
            print "["
            var mi = 0
            while mi < len(matrix):
                let row = matrix[mi]
                if type(row) == "array":
                    var parts = []
                    var mj = 0
                    while mj < len(row):
                        push(parts, str(row[mj]))
                        mj = mj + 1
                    end
                    print "  [" + join(parts, ", ") + "]"
                else:
                    print "  " + str(row)
                end
                mi = mi + 1
            end
            print "]"
            push(self.stack, nil)"""

        content = content.replace(marker, marker + handler)
        backup_file(target)
        write_file(target, content)
        print(f"[PATCHED] {target} — added OP_MATH_PRINTM handler")
        return True
    else:
        print(f"[WARN] Could not find OP_PRINT handler in {target}")
        return False

def patch_sgvm_compiler():
    """Patch src/sgvm_compiler.sage — compile math.printm() calls."""
    target = "src/sgvm_compiler.sage"
    content = read_file(target)

    if "OP_MATH_PRINTM" in content:
        print(f"[OK] {target} already handles OP_MATH_PRINTM")
        return False

    # Add OP_MATH_PRINTM to imports
    content = content.replace(
        "from sgvm_core import OP_CALL_METHOD, OP_CALL, OP_DUP",
        "from sgvm_core import OP_CALL_METHOD, OP_CALL, OP_DUP, OP_MATH_PRINTM"
    )

    helper = """

    # === math.printm() optimization ===
    proc compile_math_printm(self, args):
        if len(args) != 1:
            panic("math.printm() expects exactly 1 argument")
        end
        self.compile_expr(args[0])
        self.write_byte(OP_MATH_PRINTM)
    end

"""

    if "proc compile_expr" in content:
        marker = "proc compile_expr"
        idx = content.find(marker)
        if idx != -1:
            content = content[:idx] + helper + content[idx:]

    backup_file(target)
    write_file(target, content)
    print(f"[PATCHED] {target} — added compile_math_printm helper")
    return True

def create_test_file():
    """Create a test file for math.printm()."""
    test_code = """import math

let matrix = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]

math.printm(matrix)

let vector = [10, 20, 30]
math.printm(vector)
"""
    target = "test_math_printm.sage"
    with open(target, "w") as f:
        f.write(test_code)
    print(f"[CREATE] {target} — test file for math.printm()")
    return True

def main():
    dry_run = "--dry-run" in sys.argv
    print("=" * 60)
    print("Patching SageVM for math.printm() support")
    print("=" * 60)

    if dry_run:
        print("[DRY RUN] No files will be modified")
        return

    patch_sgvm_core()
    patch_sgvm_vm()
    patch_sgvm_compiler()
    create_test_file()

    print("=" * 60)
    print("Done. Rebuild with: ./sagemake")
    print("Test with: sage sgvmc.sage test_math_printm.sage test.sgvm && sage sgvm.sage test.sgvm")
    print("=" * 60)

if __name__ == "__main__":
    main()
