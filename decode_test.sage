import srvm_core
from srvm_core import RVInstruction
let inst = RVInstruction(0x01048073)
print "Op=" + str(inst.opcode) + " rs1=" + str(inst.rs1) + " rs2=" + str(inst.rs2)
