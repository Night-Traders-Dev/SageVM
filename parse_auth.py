import sys
import re

content = sys.stdin.read()
enum_match = re.search(r'typedef enum \{([\s\S]+?)\} BytecodeOp;', content)
if not enum_match:
    print("Enum not found")
    sys.exit(1)

enum_content = enum_match.group(1)
opcodes = []
for line in enum_content.split(','):
    line = line.strip()
    if not line: continue
    # Handle comments
    line = re.sub(r'//.*', '', line)
    line = re.sub(r'/\*.*?\*/', '', line, flags=re.S)
    match = re.search(r'(BC_OP_\w+)', line)
    if match:
        opcodes.append(match.group(1))

for i, op in enumerate(opcodes):
    print(f"{i}: {op}")
